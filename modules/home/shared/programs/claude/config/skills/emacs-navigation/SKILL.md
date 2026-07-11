---
name: emacs-navigation
description: "MUST invoke before Bash grep/find or any symbol/reference/definition lookup. Provides MCP alternatives to grep and lsp-refs vs lsp-proj-symbols selection rules."
user-invocable: false
---

# Navigation Tool Selection

## Quick reference

| Task | Tool | Fallback |
|------|------|----------|
| File symbols + treesit | `file-outline(file_path)` | — |
| Declaration source | `symbol-source(file_path, line)` | Read |
| Definition + source in one call | `def-source(identifier, file_path)` | `xref-apropos` |
| Find definition | `lsp-def(identifier, file_path)` | `xref-apropos` |
| Find implementations (from position) | `lsp-impl(file_path, line, col)` | `lsp-proj-symbols` (noisy) |
| Find usages (from position) | `lsp-refs(file_path, line, col)` | `lsp-ws-symbols` |
| Find usages (by name) | `lsp-refs-by-name(identifier, file_path)` | `lsp-refs` with position |
| Find type | `lsp-type-def(file_path, line, col)` | `lsp-def` |
| Project-only symbol search | `lsp-proj-symbols(query, file_path)` | `lsp-ws-symbols` |
| Content search + enclosing block | `grep-block(pattern, path, cap)` | Bash grep |
| Diagnostics | `getDiagnostics` | Bash |

**Before reaching for `Bash grep/find`** — pause and check the table above. Most search tasks have an MCP equivalent that returns structured, LSP-aware results. Bash grep is a last resort, not a default.

## External files (module cache, non-project paths)

LSP is configured to follow references into external files (module cache, stdlib). "File is outside the project" is NOT a reason to use grep.

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
- Pattern search across many unknown files with no target file identified yet
  (prefer `grep-block` — it returns each hit's enclosing function/block, not
  just the matching line)
- Binary or non-text files

"File is external / not in project" is never a valid reason to use grep.

## Locating a dependency's source path — jump, never `find`

To find WHERE a dependency in use lives on disk (module cache, stdlib,
`site-packages`, `node_modules`, vendored source), **navigate to it via LSP** —
never `find`/`fd`/`ls` over global paths like `~/go/pkg/mod`, `/nix/store`,
`~/.cargo`, `site-packages`.

```
Have a symbol from the dependency (type, function, import):
  def-source(symbol, any_project_file)   → definition body + its file path, one call
  lsp-def(symbol, any_project_file)      → jumps to the defining file (external path resolved)

Have only the file already (from a def jump):
  file-outline(that_path) → symbol-source / lsp-refs   (per External file protocol above)
```

The def jump RESOLVES the external path for you — the returned location is the
real on-disk file. That is how you learn the path.

❌ `find / -name '<pkg>*'` / `find ~/go/pkg/mod ...` / `fd <pkg>` — NEVER for
locating a dependency. Global `find` is slow, noisy, and guesses at layout the
LSP already knows exactly.

`find` is acceptable only for non-code file discovery with no symbol entry
point (e.g. locating a config/asset by name inside the project).

## Content search — `grep-block` (default for text/pattern search)

`grep-block(pattern, path, cap)` = ripgrep, but each hit is expanded to its
enclosing tree-sitter block. One call returns the match **plus context** —
no follow-up `file-outline`/`symbol-source`/`Read` needed to understand a hit.

Per hit it reports:
- **A** — enclosing top-level declaration: signature + `[start-end]` range (range only, no source)
- **B** — tightest enclosing named block: full source, matched lines marked `▶`
- deduped by block; header `N blocks total (M matches), showing K`

**Reach for `grep-block` FIRST when:**
- Searching a text/regex pattern, not a resolved symbol (string literals,
  comments, log messages, config keys, error text)
- You want to see *where and in what block* a pattern appears, not just the line
- No target file identified yet — pattern search across the tree
- Any time you would otherwise run `Bash rg`/`grep` for code content

**Do NOT plain-`Bash grep` for code content** — `grep-block` gives the same
match with block context in one call. Bash grep stays only for binary/non-text
files or filename listing.

**`grep-block` vs `lsp-refs` family:**
- Known symbol, "where is it used?" → `lsp-refs` / `lsp-refs-by-name` (semantic, collision-free)
- Text pattern, non-symbol match, or quick "show me the block" → `grep-block`

**cap:** default 20 distinct blocks, `0` = unlimited. Total is always reported,
never a silent cutoff. When `total > showing`, the omitted blocks are listed as
a **headers-only tail** (`file · block-type · signature · [range]`, no source) —
read that to see everything's location and expand only the ones you need,
instead of re-running with a higher `cap`. Each shown block is tagged with its
tree-sitter node type (`function_item`, `use_declaration`, …).

## Symbol search precision

`lsp-proj-symbols` = partial substring match → noisy on short/common names:

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
- LSP tools auto-start eglot on first call — no prerequisite needed. Use `open-file-lsp` only to pre-warm the server before a batch of LSP queries.