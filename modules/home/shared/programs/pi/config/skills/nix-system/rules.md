# Nix System Rules

`NIX_CONFIG_DIR` is set — all edits to derived config files (`~/.pi/agent/`, `~/.claude/`, `~/.config/`, `/etc/`) must go to their source under `$NIX_CONFIG_DIR` instead. Never edit derived paths directly.

## BLOCKING CHECK — before any Edit or Write call

Before calling Edit or Write, verify the path:

1. Is it under `~/.pi/agent/`, `~/.claude/`, `~/.config/`, or `/etc/`? → remap using the table below first
2. Is it a symlink? → resolve to Nix source first

Do NOT call Edit or Write until the path points to the Nix source.

## Path mapping

| Derived path | Nix source |
|-------------|------------|
| `~/.pi/agent/` | `$NIX_CONFIG_DIR/modules/home/shared/programs/pi/config/` |
| `~/.claude/` | `$NIX_CONFIG_DIR/modules/home/shared/programs/claude/config/` |
| `~/.config/` | corresponding module under `$NIX_CONFIG_DIR` |
| `/etc/` | system module under `$NIX_CONFIG_DIR` |

**Exceptions**: `.envrc`, project-local files, and explicitly requested temporary runtime-only files are edited directly in their derived paths.
