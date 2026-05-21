# Code Navigation (Emacs mode)

**Always prefer MCP/LSP tools over `Read`, `grep`, `find`, or `rg`.** This applies to every code exploration task — not just file analysis, but also searching for usages, finding definitions, browsing a codebase, and understanding code flow.

| Task | Tool | Fallback |
|------|------|----------|
| File analysis: mode + treesit + symbols | `file-outline` (file_path) | — |
| File analysis: declaration source | `symbol-source` (file_path + line) | Read |
| Find definition | `lsp-find-definition` (identifier + file_path) | `xref-find-apropos` |
| Find all implementations of method/interface | `lsp-project-symbols` (method_name + file_path) | `lsp-workspace-symbols` → `xref-find-apropos` |
| Find implementations (from position) | `lsp-find-implementation` (file_path + line + col) | `lsp-workspace-symbols` |
| Find all call sites / usages (from position) | `lsp-find-references` (file_path + line + col) | `lsp-workspace-symbols` |
| Find all call sites / usages (by name, no position needed) | `lsp-find-references-by-name` (identifier + file_path) | `lsp-find-references` with position |
| Find type | `lsp-find-typeDefinition` (file_path + line + col) | `lsp-find-definition` (identifier) |
| Project-wide symbol search | `lsp-workspace-symbols` (query + file_path) | `xref-find-apropos` |
| Project-only symbol search (no external noise) | `lsp-project-symbols` (query + file_path) | `lsp-workspace-symbols` |
| Diagnostics | `getDiagnostics` | Bash |

> **`lsp-find-references`**: position-based (file_path + line + col), returns all call sites. Use when you already have a location and want all usages. Use `lsp-workspace-symbols` when you only have a name.

## Chained navigation pipelines

Use these pipelines to minimize context: chain tools so each call's output feeds the next, avoiding file reads until absolutely necessary.

**Pipeline A — Interface change impact** ("If I remove method X, what breaks?")
```
0. lsp-project-symbols(interface_name)        → locate interface file (skip if path already known)
1. imenu-list-symbols(interface_file)         → get method names
2. lsp-project-symbols(method_name)           → all implementors (no external noise)
3. lsp-project-symbols(interface_type_name)   → all callers/usages of the interface type
```
Zero file reads. Complete impact picture before touching any code.

> **Precision note:** `lsp-project-symbols(method_name)` returns every type with that method name, including types that happen to share the name but don't implement the interface. For exact implementors only, use `lsp-find-implementation(interface_file, line, col)` at the method's position in the interface definition.

**Pipeline B — Type structure exploration** ("What does this type look like?")
```
1. lsp-find-definition(type_name, any_project_file) → definition file + line
   fallback: xref-find-apropos(type_name) if lsp-find-definition returns nothing
2. file-outline(definition_file)                    → treesit availability + all methods with line numbers
3. symbol-source(file, line) [only if logic needed] → full method body via tree-sitter
   fallback: Read with tight offset/limit if symbol-source is insufficient
```
> **Step 1 tip:** `lsp-find-definition` resolves the identifier in the scope of the context file's package. Pass a file from the **same package where the symbol is defined** — importing the package is not enough. For example, to find `RetryTask`, pass `retry/retry_task.go`, not a file that merely imports the retry package. If you don't know which file to pass, use `lsp-project-symbols(symbol_name)` first to locate the definition file, then pass that file as context.

**Pipeline C — Symbol propagation** ("Where does this field/value flow?")

**Short form** (function or type name known, no position):
```
1. lsp-find-references-by-name(identifier, file)  → all call sites in one step
2. symbol-source(file, line) [for each site]       → read the context around each usage
```

**Long form** (struct field or positional context needed):
```
1. imenu-list-symbols(file)                        → field line + column (declaration position)
2. lsp-find-references(file, line, col)            → all read/write sites across the project
3. symbol-source(file, line) [for each site]       → read the context around each usage
```
> **Why not `lsp-workspace-symbols` here:** symbol search returns *declarations*, not *usages*. A field declared once but used in 10 places requires `lsp-find-references` to see all 10 sites. Use `lsp-workspace-symbols` only when you don't yet have a position to anchor from.
> **`lsp-find-references-by-name`**: preferred for the short form — resolves the definition position internally via workspace/symbol (exact name match, project-local), then calls textDocument/references. Use the long form only when the symbol is a struct field (not returned by workspace/symbol as a standalone name) or when multiple symbols share the same name.

**Finding all implementations of an interface method** (e.g., every type that implements `Flush`):

Use `lsp-project-symbols(query="MethodName", file_path=<any project file>)` — returns project-only results with no external package noise. This is always preferred over `grep` — do NOT reach for Bash grep when you need to find all implementors.

For exact implementors (excludes types that share the method name but don't satisfy the interface), position the cursor on the method in the interface definition and call `lsp-find-implementation(file_path, line, col)`.

Example: to find all types implementing a `Closer` interface's `Close` method, first try `lsp-project-symbols(query="Close")`, then verify with `lsp-find-implementation` if `Close` is common enough to cause false positives.

## treesit-info

Available if buffer major-mode ends in `-ts-mode` or `(treesit-parser-list)` returns non-empty. Load schema via ToolSearch `"treesit-info"` max_results:2 before use. Always pass `line` + `column` to target a specific node — **`whole_file: true` is prohibited** because it dumps the full character-level AST and is more expensive to process than reading the file directly.

**If treesit-info returns a leaf/keyword node** (e.g. `Node Type: func`, `Node Type:`): the cursor landed on a token, not a declaration. Do NOT fall back to Read immediately — first retry with `include_ancestors: true` to walk up to the enclosing declaration node (e.g. `method_declaration`, `function_declaration`). Only fall back to Read if the ancestor chain is still insufficient.

## LSP position tools and eglot

**LSP position tools** (`lsp-find-implementation`, `lsp-find-typeDefinition`): line is 1-based, column is 0-based. Require eglot active.

**`lsp-find-typeDefinition` limitations:**
- gopls does not support typeDefinition for interface types or struct field declarations — use `lsp-find-definition` as fallback in those cases.

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

This applies to all LSP-supported languages. `lsp-find-definition` covers every project file without knowing the path in advance. For Emacs Lisp symbols, see `elisp.md` — `describe-symbol` is the primary tool there.

---

## Tool selection efficiency

**`lsp-workspace-symbols` and `xref-find-apropos` noise**
- Both `lsp-workspace-symbols` and `xref-find-apropos` include external packages (`/go/pkg/mod/`, `/nix/store/`) in results. `xref-find-apropos` is NOT a noise-free fallback — it returns just as many external hits.
- For project-internal symbol search (including partial-name or pattern queries), always prefer `lsp-project-symbols` first — it filters out external packages automatically. Fall back to `xref-find-apropos` only when `lsp-project-symbols` returns no results.

**`symbol-source` vs `Read` for small files**
- `symbol-source` is optimal for a single targeted symbol. When you need 3+ functions from the same small file (< ~300 lines), a single `Read` with `offset`/`limit` is fewer round-trips than repeated `symbol-source` calls.
- Always call multiple `symbol-source` requests **in parallel** when you need several symbols from the same or different files.