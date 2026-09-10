---
name: emacs-navigation
description: "MUST invoke before Bash grep/find or any symbol/reference/definition lookup. Provides MCP alternatives to grep and lsp-refs vs lsp-proj-symbols selection rules."
user-invocable: false
---
# Navigation Tool Selection

Multi-file or open-ended explore (find X, what call Y, map dir): use `Explore` agent — Emacs MCP-aware override of builtin. Table below only for one targeted lookup.

## Quick reference

| Task | Tool | Fallback |
|------|------|----------|
| File symbols + treesit (one or more comma-separated files) | `file-outline(file_path)` | — |
| Declaration source | `symbol-source(file_path, line)` | Read |
| Definition + source in one call | `def-source(identifier, file_path)` | `xref-apropos` |
| Caller/callee graph, recursive | `symbol-graph(identifier, file_path, direction, depth, cap, include_source)` | `lsp-refs-by-name` |
| Find definition | `lsp-def(identifier, file_path)` | `xref-apropos` |
| Find implementations (from position) | `lsp-impl(file_path, line, col)` | `lsp-proj-symbols` (noisy) |
| Find usages (from position) | `lsp-refs(file_path, line, col)` | `lsp-ws-symbols` |
| Find usages (by name) | `lsp-refs-by-name(identifier, file_path)` | `lsp-refs` with position |
| Find type | `lsp-type-def(file_path, line, col)` | `lsp-def` |
| Project-only symbol search | `lsp-proj-symbols(query, file_path)` | `lsp-ws-symbols` |
| Content search + enclosing block | `grep-block(pattern, path, cap, headers)` | Bash grep |
| Clone index — blocks sharing normalized content, recorded as graph nodes | `trace(pattern, path, cap, ask, files)` | `grep-block` then read by hand |
| What registers / orders / requires a symbol, read back with no LSP round trip | `graph(from, kinds, depth, direction, path)` | re-run `trace` |
| What changed (commit / range / tree) | `review-changes(target, mode, path, cap)` | Bash git diff |
| Repository structure, depth-limited | `structure-tree(path, depth, symbols, pattern, cap)` | Bash ls/find |
| Structural rewrite | `ast-rewrite(pattern, rewrite, path)` | Edit |
| Diagnostics | `getDiagnostics` | Bash |

**Before reaching for `Bash grep/find`** — stop, check table. Most search task have MCP twin that give structured LSP-aware result. Bash grep last resort, not default.

## External files (module cache, non-project paths)

LSP follow reference into external file (module cache, stdlib). "File outside project" NOT reason for grep.

**WRONG**: "This file is in `/go/pkg/mod/` → LSP won't index it → use grep"
**RIGHT**: "This file is in `/go/pkg/mod/` → open-file-lsp or file-outline first"

```
External file protocol (LSP auto-initializes on any call — no open-file-lsp needed):
1. file-outline(external_file_path)        → symbols + line numbers via treesit
2. symbol-source(external_file_path, line) → full body of target symbol
3. lsp-def / lsp-refs work on external files directly
4. Read(external_file_path, offset, limit) → only if above insufficient
❌ Bash grep -n "pattern" external_file    → NEVER
```

**Grep is allowed ONLY when:**
- Pattern hunt over many unknown file, no target file yet
  (prefer `grep-block` — it give each hit enclosing function/block, not
  just match line)
- Binary or non-text file

"File external / not in project" never valid reason for grep.

## Locating a dependency's source path — jump, never `find`

To find WHERE dep live on disk (module cache, stdlib,
`site-packages`, `node_modules`, vendored source), **navigate to it via LSP** —
never `find`/`fd`/`ls` over global path like `~/go/pkg/mod`, `/nix/store`,
`~/.cargo`, `site-packages`.

```
Have a symbol from the dependency (type, function, import):
  def-source(symbol, any_project_file)   → definition body + its file path, one call
  lsp-def(symbol, any_project_file)      → jumps to the defining file (external path resolved)

Have only the file already (from a def jump):
  file-outline(that_path) → symbol-source / lsp-refs   (per External file protocol above)
```

Def jump RESOLVE external path for you — returned location is real on-disk file. That how you learn path.

❌ `find / -name '<pkg>*'` / `find ~/go/pkg/mod ...` / `fd <pkg>` — NEVER for
find dep. Global `find` slow, noisy, guess layout LSP already know exact.

`find` ok only for non-code file hunt with no symbol door (e.g. find config/asset by name inside project).

## Content search — `grep-block` (default for text/pattern search)

`grep-block(pattern, path, cap)` = ripgrep, but each hit grow to its
enclosing tree-sitter block. One call give match **plus context** —
no follow-up `file-outline`/`symbol-source`/`Read` need to understand hit.

Per hit it report:
- **A** — enclosing top-level declaration: signature + `[start-end]` range (range only, no source)
- **B** — tightest enclosing named block: full source, matched lines marked `▶`
- deduped by block; header `N blocks total (M matches), showing K`

**Reach for `grep-block` FIRST when:**
- Hunt text/regex pattern, not resolved symbol (string literal,
  comment, log message, config key, error text)
- You want see *where and in what block* pattern show, not just line
- No target file yet — pattern hunt over tree
- Any time you would else run `Bash rg`/`grep` for code content

**Do NOT plain-`Bash grep` for code content** — `grep-block` give same
match with block context in one call. Bash grep stay only for binary/non-text
file or filename list.

**`grep-block` vs `lsp-refs` family:**
- Known symbol, "where is it used?" → `lsp-refs` / `lsp-refs-by-name` (semantic, collision-free)
- Text pattern, non-symbol match, or quick "show me the block" → `grep-block`

## Structural rewrite — `ast-rewrite`

`ast-rewrite(pattern, rewrite, path)` match syntax tree and swap what
it find. Both side are code fragment; `$A` bind one node and `$$$A` bind
node list: `foo($A, $B)` → `bar($B, $A)`. Whitespace and line break
ignored, node kind must agree.

It rewrite only. Search stay with `grep-block`, and `dry_run` show what
rewrite would touch without write.

**`ast-rewrite` vs `Edit`** — grab `ast-rewrite` when same shape
show more than once, indent uncertain, or lookalike text sit near.
Those three way textual edit land wrong place, and none can touch structural match: comment or string that only look like code never hit, and format difference not matter.

Pattern that match nothing come back with own parse tree, so pass
`lang` to read why. File with no tree-sitter parser cannot rewrite this
way — use `Edit` there.

**cap:** default 20 distinct block, `0` = unlimited. Total always reported,
never silent cutoff. When `total > showing`, omitted block listed as
**headers-only tail** (`file · block-type · signature · [range]`, no source) —
read that to see all location and expand only ones you need,
not re-run with higher `cap`. Each shown block tagged with its
tree-sitter node type (`function_item`, `use_declaration`, …).

**headers mode** (`headers` = any non-empty string): give EVERY hit as
headers-only line (block type + signature + range, no source, `cap` ignored).
Use as **first pass on broad search** — survey all location cheap,
then re-run without `headers` (narrow pattern/path or aim at block
you want) to pull source. Two-phase = minimal context on wide search.

## Symbol search precision

`lsp-proj-symbols` = partial substring match → noisy on short/common name:

| Query | Results | Problem |
|-------|---------|---------|
| `lsp-proj-symbols("User")` | 50+ | Unrelated: UserService, userId, createUser included |
| `lsp-proj-symbols("Type")` | 80+ | Field/method/type names mixed |

**Rule: `lsp-proj-symbols` = discovery/existence check only. For "where is this used?", MUST use `lsp-refs` family.**

**Usage tracking — preferred:**
```
Definition location known:
1. file-outline(target_file)     → get definition line number
2. lsp-refs(file, line, col)     → position-based, zero name collision

Name only known:
lsp-refs-by-name(identifier, any_project_file)  → more precise than proj-symbols
```

**Re-export detection:** `lsp-refs-by-name` results all inside definition file → unused externally. Conclude "no external usage" immediately.

**`[textual fallback]` in output** mean server resolve nothing or
give no reference, so tool search text instead. Those hit are
whole-word match, not semantic: unrelated symbol share name and
mention in doc/comment included. Read as lead, not reference
set. A `... N more files matched but were not inspected` tail mean search
hit file cap — narrow identifier, not trust list as complete.

## Usage in one call — `symbol-graph`

`symbol-graph(identifier, file_path, direction, depth, cap, include_source)`
answer "definition plus every call site, and what those caller are" without
`file-outline` → `symbol-source` → `lsp-refs-by-name` → `grep-block` round trip.

- `direction`: `callers` (default), `callees`, `both`
- `depth` default 2, `cap` default 40 nodes (`0` = unlimited)
- `include_source` (any non-empty string) add each node definition source —
  **`depth 1` + `include_source`** is "definition + all call site + their
  body" shape, in one response

Server that serve `callHierarchy` give real indented multi-level walk, with
repeat node marked `(seen)`. Server that not — plus multiplexer that
advertise capability then reject request — drop to depth-1
caller report whose line carry each call site enclosing declaration, and
cannot answer `callees`. Output always name which path made it.

Prefer `symbol-graph` over `lsp-refs-by-name` when you need caller
identity or context, not just location.

## Chained pipelines

**Interface change impact** ("If I remove method X, what breaks?")
```
1. lsp-impl(interface_file, line, col)  → all implementors (position-based, precise)
2. lsp-proj-symbols(interface_type)     → callers of the interface type
```

**Type structure** ("What does this type look like?")
```
Fast: def-source(type_name, any_project_file)   → definition in one call
Full: lsp-def → file-outline → symbol-source
```

**Symbol propagation** ("Where does this flow?")
```
Short: lsp-refs-by-name(identifier, file) → all call sites
Long:  imenu-symbols(file) → field line+col → lsp-refs → symbol-source
```

## LSP / eglot notes

- Line 1-based, column 0-based
- `lsp-type-def` limitation: gopls doesn't support typeDefinition for interfaces/struct fields → fall back to `lsp-def`
- LSP tool auto-start eglot on first call — no prereq need. Use `open-file-lsp` only to pre-warm server before batch of LSP query.