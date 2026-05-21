# Code Navigation (Emacs mode)

**Always prefer MCP/LSP tools over `Read`, `grep`, `find`, or `rg`.** This applies to every code exploration task — not just file analysis, but also searching for usages, finding definitions, browsing a codebase, and understanding code flow.

| Task | Tool | Fallback |
|------|------|----------|
| File analysis: mode + treesit + symbols | `file-outline` (file_path) | — |
| File analysis: declaration source | `symbol-source` (file_path + line) | Read |
| Find definition | `lsp-find-definition` (identifier + file_path) | `xref-find-apropos` |
| Find all implementations of method/interface | `lsp-workspace-symbols` (method_name + file_path) | `xref-find-apropos` |
| Find implementations (from position) | `lsp-find-implementation` (file_path + line + col) | `lsp-workspace-symbols` |
| Find all call sites / usages (from position) | `lsp-find-references` (file_path + line + col) | `lsp-workspace-symbols` |
| Find type | `lsp-find-typeDefinition` (file_path + line + col) | `describe-symbol` |
| Project-wide symbol search | `lsp-workspace-symbols` (query + file_path) | `xref-find-apropos` |
| Project-only symbol search (no external noise) | `lsp-project-symbols` (query + file_path) | `lsp-workspace-symbols` |
| Symbol docs | `describe-symbol` (name) | Read |
| Diagnostics | `getDiagnostics` | Bash |

> **`lsp-find-references`**: position-based (file_path + line + col), returns all call sites. Use when you already have a location and want all usages. Use `lsp-workspace-symbols` when you only have a name.

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

## treesit-info

Available if buffer major-mode ends in `-ts-mode` or `(treesit-parser-list)` returns non-empty. Load schema via ToolSearch `"treesit-info"` max_results:2 before use. Always pass `line` + `column` to target a specific node — **`whole_file: true` is prohibited** because it dumps the full character-level AST and is more expensive to process than reading the file directly.

**If treesit-info returns a leaf/keyword node** (e.g. `Node Type: func`, `Node Type:`): the cursor landed on a token, not a declaration. Do NOT fall back to Read immediately — first retry with `include_ancestors: true` to walk up to the enclosing declaration node (e.g. `method_declaration`, `function_declaration`). Only fall back to Read if the ancestor chain is still insufficient.

## LSP position tools and eglot

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

## Symbol-to-file lookup (sequential constraint)

Every "where is X defined?" or "what file contains X?" query requires this sequence regardless of language. You must not call `Bash find` or `grep` until you have answered each evaluation question and committed to the path.

---

**Step 1 — Evaluate: What kind of symbol is it?**

| Symbol type | Primary tool | Why |
|-------------|-------------|-----|
| Project code (Go, TS, Python…) | `lsp-find-definition(identifier, file_path)` | LSP gives precise cross-file definitions |
| Unknown / partial name | `xref-find-apropos(pattern)` or `lsp-workspace-symbols(query)` | Pattern search across loaded symbols or workspace |

> **Emacs Lisp symbols** (`.el` files, Emacs internals, elpaca packages): see `elisp.md` — `describe-symbol` is the primary tool there.

Commit out loud before proceeding:
> "Symbol `[name]` is project code. Primary tool: **lsp-find-definition**."

---

**Step 2 — Evaluate: Did Step 1 return a location?**

- **YES** → commit: "Found at `[path]:[line]`. Next: **file-outline** or **symbol-source**."
- **NO** (symbol not found / LSP miss) → try `xref-find-apropos` or `lsp-workspace-symbols` as fallback.

---

**Gate check — before calling `Bash find`, `grep`, or `rg`, confirm:**
1. The appropriate Step 1 tool was called → returned no result
2. `xref-find-apropos` / `lsp-workspace-symbols` was called → no matches
3. Only then: Bash is justified

This applies to **all languages**. `describe-symbol` covers every loaded Emacs package; `lsp-find-definition` covers every LSP-supported project file. Neither requires knowing the file path in advance.

---

## Tool selection efficiency

**`lsp-workspace-symbols` noise**
- Results always include external packages (`/go/pkg/mod/`, `/nix/store/`). Filter to project paths only.
- If the query is a common name or you only need project-internal symbols, try `xref-find-apropos` first — it returns project-local hits with far less noise.

**`symbol-source` vs `Read` for small files**
- `symbol-source` is optimal for a single targeted symbol. When you need 3+ functions from the same small file (< ~300 lines), a single `Read` with `offset`/`limit` is fewer round-trips than repeated `symbol-source` calls.
- Always call multiple `symbol-source` requests **in parallel** when you need several symbols from the same or different files.