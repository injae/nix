---
name: emacs-dev
description: Use this skill at the very start of every session to detect whether Claude is running inside Emacs and configure MCP tools accordingly. Triggers automatically on session start per CLAUDE.md instructions.
user-invocable: true
allowed-tools:
  - Bash(env*)
  - ToolSearch
---

# Emacs Environment Detection

Detect whether this session is running inside Emacs and configure MCP tools for the session.

## Steps

1. Run the following in parallel via Bash:
   - `env | grep -E 'INSIDE_EMACS|TERM_PROGRAM'`
   - `ls .envrc flake.nix 2>/dev/null`

2. **If `INSIDE_EMACS` is set OR `TERM_PROGRAM=emacs`** — Emacs session detected:
   - Discover and load Emacs MCP tool schemas via two ToolSearch calls (run in parallel):
     - Query `"emacs-tools"` with `max_results: 10` — finds all `mcp__emacs-tools__*` tools
     - Query `"+ide getDiagnostics"` with `max_results: 3` — finds `mcp__ide__getDiagnostics`
   - Use whatever tools are returned; do not assume specific tool names exist.
   - For the rest of this session, prefer these MCP tools over Bash for code navigation.
   - Reply: "Emacs mode active — MCP tools loaded."

3. **If neither variable is present** — not in Emacs:
   - Use standard Bash tools (`grep`, `find`, etc.) for code navigation.
   - Reply: "Not in Emacs — using standard Bash tools."

4. **If both `.envrc` and `flake.nix` exist in the working directory:**
   - Prefix all shell commands with `direnv exec .` for the rest of the session.
   - Reply: "direnv + nix flake detected — using `direnv exec .` for shell commands."

## Code navigation (Emacs mode only)

**Always prefer LSP/eglot MCP tools over `grep`, `find`, or `rg` for symbol lookups.** The language server returns semantically accurate results; shell tools match text and produce false positives.

### Tool priority for code tasks

| Task | Use this tool first | Fall back to |
|------|---------------------|--------------|
| Go to / find a definition | `lsp-find-definition` (identifier + file_path) | `xref-find-apropos` |
| Find all call sites / usages | `lsp-find-references` (identifier + file_path) | `xref-find-references` |
| Find interface implementations | `lsp-find-implementation` (file_path + line + col) | Bash grep |
| Find type behind a variable | `lsp-find-typeDefinition` (file_path + line + col) | `describe-symbol` |
| Search symbols by name pattern | `xref-find-apropos` (pattern + file_path) | Bash grep |
| Inspect a symbol's docs/source | `describe-symbol` (name) | Read file |
| Check compiler / linter errors | `getDiagnostics` | Bash |

### Notes on LSP tools

- `lsp-find-definition` and `lsp-find-references` take an **identifier string** and a **file_path** for backend context — use any open file in the same project.
- `lsp-find-implementation` and `lsp-find-typeDefinition` are **position-based**: provide the exact file, line (1-based), and column (0-based) where the symbol appears.
- These tools require eglot to be active on the file. If eglot is not running, fall back to `xref-find-apropos` or Bash.

## Build commands (projects with direnv + nix flake)

If the project root contains both `.envrc` and `flake.nix`, always prefix shell commands with `direnv exec .` so the nix devShell is loaded. Without it, toolchain binaries and linker libraries provided by nix will be missing.

**At session start:** check for `.envrc` and `flake.nix` in the working directory. If both exist, use `direnv exec .` for all shell commands for the rest of the session.

```
direnv exec . <any command>
```
