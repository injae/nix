# Code Navigation (Emacs mode)

**Always prefer MCP/LSP tools over `Read`, `grep`, `find`, or `rg`.**

| Task | Tool | Fallback |
|------|------|----------|
| File analysis: mode + treesit + symbols | `file-outline` (file_path) | — |
| File analysis: declaration source | `symbol-source` (file_path + line) | Read |
| Definition + full source in one call | `def-source` (identifier + file_path) | `xref-apropos` |
| Find definition | `lsp-def` (identifier + file_path) | `xref-apropos` |
| Find all implementations of method/interface | `lsp-proj-symbols` (method_name + file_path) | `lsp-ws-symbols` → `xref-apropos` |
| Find implementations (from position) | `lsp-impl` (file_path + line + col) | `lsp-ws-symbols` |
| Find all call sites / usages (from position) | `lsp-refs` (file_path + line + col) | `lsp-ws-symbols` |
| Find all call sites / usages (by name) | `lsp-refs-by-name` (identifier + file_path) | `lsp-refs` with position |
| Find type | `lsp-type-def` (file_path + line + col) | `lsp-def` (identifier) |
| Project-wide symbol search | `lsp-ws-symbols` (query + file_path) | `xref-apropos` |
| Project-only symbol search (no external noise) | `lsp-proj-symbols` (query + file_path) | `lsp-ws-symbols` |
| Diagnostics | `getDiagnostics` | Bash |

## Chained navigation pipelines

Chain tools so each call feeds the next — avoid file reads until necessary.

**Pipeline A — Interface change impact** ("If I remove method X, what breaks?")
```
0. lsp-proj-symbols(interface_name)        → locate interface file (skip if known)
1. imenu-symbols(interface_file)           → get method names
2. lsp-proj-symbols(method_name)           → all implementors
3. lsp-proj-symbols(interface_type_name)   → all callers of the interface type
```
For exact implementors (not just name-matched), use `lsp-impl(interface_file, line, col)` at the method position in the interface definition.

**Pipeline B — Type structure exploration** ("What does this type look like?")
```
Fast path:
1. def-source(type_name, any_project_file)   → definition source in one call

Full path:
1. lsp-def(type_name, any_project_file)      → definition file + line
   fallback: xref-apropos(type_name)
2. file-outline(definition_file)             → treesit availability + methods
3. symbol-source(file, line)                 → full method body (if needed)
```
> `lsp-def` resolves in the context file's package scope. Pass a file from the **same package** as the symbol. If unknown, run `lsp-proj-symbols(symbol_name)` first to locate it.

**Pipeline C — Symbol propagation** ("Where does this field/value flow?")
```
Short form (name known):
1. lsp-refs-by-name(identifier, file)  → all call sites in one step
2. symbol-source(file, line)           → context around each usage

Long form (struct field / positional):
1. imenu-symbols(file)                 → field line + column
2. lsp-refs(file, line, col)           → all read/write sites
3. symbol-source(file, line)           → context around each usage
```
> Use long form only for struct fields (not returned by workspace/symbol) or name collisions.

## treesit-info

Available if major-mode ends in `-ts-mode`. Always pass `line` + `column` — **`whole_file: true` is prohibited**. If result is a leaf/keyword node, retry with `include_ancestors: true` to walk up to the enclosing declaration before falling back to Read.

## LSP tools and eglot

Line is 1-based, column is 0-based. Require eglot active.

**`lsp-type-def` limitation:** gopls doesn't support typeDefinition for interface types or struct field declarations — fall back to `lsp-def`.

**If eglot is not active:** open a background buffer to activate it, then retry:
```elisp
(find-file-noselect "/path/to/any/file/in/project")
```
If any LSP tool already succeeded this session, eglot is active — pass any open project file as `file_path` instead. The eglot server is project-scoped, not file-scoped.

## Symbol lookup gate check

Before calling `Bash find` / `grep` / `rg`, confirm these failed first:
1. `lsp-def(identifier, file_path)` — precise cross-file definition
2. `xref-apropos` or `lsp-ws-symbols` — pattern/partial-name fallback

For Emacs Lisp symbols, see `elisp.md` — `describe-symbol` is the primary tool.

## Tool selection efficiency

**Prefer `lsp-proj-symbols` over `lsp-ws-symbols` / `xref-apropos`** — both include external packages (`/go/pkg/mod/`, `/nix/store/`). `lsp-proj-symbols` filters them out automatically.

**`symbol-source` vs `Read`:** optimal for a single symbol. For 3+ functions from the same small file (< ~300 lines), a single `Read` with `offset`/`limit` is fewer round-trips. Run multiple `symbol-source` calls **in parallel**.