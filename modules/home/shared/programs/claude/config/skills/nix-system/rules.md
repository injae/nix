# Nix Configuration Rules

`NIX_CONFIG_DIR` is set — all edits to derived config files (`~/.claude/`, `~/.config/`, `/etc/`) must go to their source under `$NIX_CONFIG_DIR` instead. Never edit derived paths directly.

If `.envrc` exists in the current working directory, delegate environment-handling behavior to the `direnv` skill.

## Path mapping

| Derived path | Nix source |
|-------------|------------|
| `~/.claude/` | `$NIX_CONFIG_DIR/modules/home/shared/programs/claude/config/` |
| `~/.config/` | corresponding module under `$NIX_CONFIG_DIR` |
| `/etc/` | system module under `$NIX_CONFIG_DIR` |

**Exceptions**: `.envrc`, project-local files, and `CLAUDE.local.md` are edited directly in their derived paths.

When creating a new file anywhere under `$NIX_CONFIG_DIR`, immediately run `git add <file>` — Nix flakes only see git-tracked files.

Never run `just switch` yourself. The user runs it manually — do not remind them or mention it as a closing remark.