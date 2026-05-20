---
name: emacs-dev
description: "MUST invoke this skill at the very start of every session without exception. Detects whether Claude is running inside Emacs and configures MCP tools accordingly. This is a MANDATORY step — do NOT skip it, even if the session appears non-Emacs or the task seems unrelated. Triggers automatically on session start per CLAUDE.md instructions."
user-invocable: true
allowed-tools:
  - Bash(env*)
  - ToolSearch
---

# Emacs Environment Detection

Run: `env | grep -E 'INSIDE_EMACS|TERM_PROGRAM'`

**If `INSIDE_EMACS` is set OR `TERM_PROGRAM=emacs`:** load MCP tool schemas via two parallel ToolSearch calls:
- `"emacs-tools"` max_results:25
- `"+ide getDiagnostics"` max_results:3

Prefer MCP tools over Bash for all code navigation. Reply: "Emacs mode active — MCP tools loaded."

**Otherwise:** use standard Bash tools. Reply: "Not in Emacs — using standard Bash tools."

## Code navigation (Emacs mode)

**Always prefer MCP/LSP tools over `Read`, `grep`, `find`, or `rg`.** This applies to every code exploration task — not just file analysis, but also searching for usages, finding definitions, browsing a codebase, and understanding code flow.

| Task | Tool | Fallback |
|------|------|----------|
| File analysis Step 1+2: mode + treesit + symbols | `file-outline` (file_path) | — |
| File analysis Step 3+4: declaration source | `symbol-source` (file_path + line) | Read |
| Find definition | `lsp-find-definition` (identifier + file_path) | `xref-find-apropos` |
| Find all implementations of method/interface | `lsp-workspace-symbols` (method_name + file_path) | `xref-find-apropos` |
| Find implementations (from position) | `lsp-find-implementation` (file_path + line + col) | `lsp-workspace-symbols` |
| Find type | `lsp-find-typeDefinition` (file_path + line + col) | `describe-symbol` |
| Project-wide symbol search | `lsp-workspace-symbols` (query + file_path) | `xref-find-apropos` |
| Symbol docs | `describe-symbol` (name) | Read |
| Diagnostics | `getDiagnostics` | Bash |

> **⚠️ `lsp-find-references` is unreliable** — returns "no identifier found" even with a valid identifier string because it internally requires a cursor position. Do NOT use it. Use `lsp-workspace-symbols` to find usages instead.

## Chained navigation pipelines

Use these pipelines to minimize context: chain tools so each call's output feeds the next, avoiding file reads until absolutely necessary.

**Pipeline A — Interface change impact** ("If I remove method X, what breaks?")
```
1. imenu-list-symbols(interface_file)         → get method names
2. lsp-workspace-symbols(method_name)         → all implementors (filter to project paths)
3. lsp-workspace-symbols(interface_type_name) → all callers/usages of the interface type
```
Zero file reads. Complete impact picture before touching any code.

**Pipeline B — Type structure exploration** ("What does this type look like?")
```
1. lsp-find-definition(type_name, any_project_file) → definition file + line
2. imenu-list-symbols(definition_file)              → all methods of that type
3. treesit-info(line, col) [only if body needed]    → byte range → Read with tight offset/limit
```

**Pipeline C — Symbol propagation** ("Where does this field/value flow?")
```
1. imenu-list-symbols(file)              → field line number
2. lsp-workspace-symbols(field_name)     → all symbols with that name (narrow by type if ambiguous)
3. lsp-find-definition(name, file)       → confirm origin declaration
```

**Finding all implementations of an interface method** (e.g., every type that implements `Flush`):
Use `lsp-workspace-symbols(query="MethodName", file_path=<any project file>)`. The LSP server returns every symbol in the workspace matching that name with file + line. Filter results to project paths only (ignore `/go/pkg/mod/`, `/nix/store/`, etc.). This is always preferred over `grep` — do NOT reach for Bash grep when you need to find all implementors.

Example: to find all types implementing a `GracefulTask.Flush` method, call `lsp-workspace-symbols(query="Flush")` and look for entries under your project root.

**treesit-info:** available if buffer major-mode ends in `-ts-mode` or `(treesit-parser-list)` returns non-empty. Load schema via ToolSearch `"treesit-info"` max_results:2 before use. Always pass `line` + `column` to target a specific node — **`whole_file: true` is prohibited** because it dumps the full character-level AST and is more expensive to process than reading the file directly.

**If treesit-info returns a leaf/keyword node** (e.g. `Node Type: func`, `Node Type:`): the cursor landed on a token, not a declaration. Do NOT fall back to Read immediately — first retry with `include_ancestors: true` to walk up to the enclosing declaration node (e.g. `method_declaration`, `function_declaration`). Only fall back to Read if the ancestor chain is still insufficient.

**LSP position tools** (`lsp-find-implementation`, `lsp-find-typeDefinition`): line is 1-based, column is 0-based. Require eglot active.

**If eglot is not active** (project not loaded in Emacs): open a background buffer via `call-function` to activate eglot, then retry the LSP tool.
```elisp
(find-file-noselect "/path/to/any/file/in/project")
```
Fall back to `xref-find-apropos` or Bash only if the background buffer approach also fails.

> **IMPORTANT — avoid `find-file-noselect` when eglot is already running:**
> If any LSP tool has already succeeded in this session, eglot is active for the project.
> Do NOT call `find-file-noselect` on additional files — it triggers Emacs hooks
> (recentf, projectile, etc.) and can disturb the user's editing session.
> Instead, pass **any already-open file in the same project** as `file_path` to all LSP tools.
> The eglot server is project-scoped, not file-scoped.
>
> **`lsp-workspace-symbols` specifically**: internally uses `eglot--request` directly and
> searches for an already-open project buffer before ever calling `find-file-noselect`.
> Pass any open file in the project as `file_path` — the specific file does not need to be open.

## File analysis flow

Every file analysis requires an explicit evaluate → commit → execute sequence. You must not call the next tool until you have answered the evaluation question and committed to the path. One completed sequence does NOT cover other files — each file requires its own pass.

---

### Step 1 — Evaluate: Is tree-sitter available?

Call `file-outline` with the absolute file path. Returns `major-mode`, `treesit` availability, and the full symbol list with line numbers in one call. Opens the file in the background if needed.

Answer YES or NO:
- **YES** if `treesit: available`
- **NO** otherwise

Commit out loud before proceeding:
> "Tree-sitter is **[available / not available]** for `[file]`. Next tool: **[symbol-source / Read]**."

---

### Step 2 (tree-sitter = YES) — Evaluate: What source do I need?

The symbol list from Step 1 contains line numbers. Identify the target symbol and its line number.

Commit out loud before proceeding:
> "Target `[symbol]` is at line [N]. Next tool: **symbol-source** at line [N]."

**The line numbers from `file-outline` are inputs to `symbol-source`. They are NOT permission to call `Read`.**

---

### Step 3 (tree-sitter = YES) — Get source

Call `symbol-source(file_path, line)`. The tool uses tree-sitter internally to find the exact declaration bounds and returns the full source.

Answer YES or NO — is the returned source complete and correct?
- **YES** → done.
- **NO** (truncated or wrong) → commit out loud before proceeding:
  > "symbol-source insufficient. Falling back to **Read** at lines [start–end] only."

---

### Step 4 — Read (only if Step 3 = NO, or tree-sitter unavailable)

Call `Read` with a specific line range. Do not read the whole file unless the range cannot be determined.

---

**Gate check — before calling `Read`, you must confirm:**
1. `file-outline` was called for this file → structure obtained
2. If tree-sitter available: `symbol-source` was called → result was insufficient
3. Only then: `Read` is justified

If you cannot confirm steps 1–2, you must go back and complete them first.

## Elisp editing

When editing `.el` files, verify parenthesis balance via `call-function`:
- function: `claude-code-ide-mcp-check-elisp-parens`
- args_json: `["/absolute/path/to/file.el"]`

Returns `t` if balanced. If unavailable, count `(` and `)` manually.
