---
name: nix-system
description: "Use at session start when NIX_CONFIG_DIR is set or flake.nix exists in cwd. Enforce Nix-managed config rules: never edit derived paths directly; edit sources under NIX_CONFIG_DIR."
user-invocable: true
---

# Nix System Configuration

`NIX_CONFIG_DIR` is set — all edits to derived config files (`~/.claude/`, `~/.config/`, `/etc/`) must go to their source under `$NIX_CONFIG_DIR` instead. Never edit derived paths directly.

## BLOCKING CHECK — before any Edit or Write call

Before calling Edit or Write, verify the path:

1. Is it under `~/.claude/`, `~/.config/`, or `/etc/`? → remap using the table below first
2. Is it a symlink? → resolve to Nix source first

Do NOT call Edit or Write until the path points to the Nix source.

## Path mapping

| Derived path | Nix source |
|-------------|------------|
| `~/.claude/` | `$NIX_CONFIG_DIR/modules/home/shared/programs/claude/config/` |
| `~/.config/` | corresponding module under `$NIX_CONFIG_DIR` |
| `/etc/` | system module under `$NIX_CONFIG_DIR` |

**Exceptions**: project-local files and `CLAUDE.local.md` are edited directly in their derived paths.

When creating a new file anywhere under `$NIX_CONFIG_DIR`, immediately run `git add <file>` — Nix flakes only see git-tracked files.

Never run `just switch` yourself. The user runs it manually — do not remind them or mention it as a closing remark.

## Additional sub-files

| File | When to Read |
|------|-------------|
| `claude-config.md` | Claude Code config work (skills, hooks, CLAUDE.md, settings.json, `~/.claude/`) |
| `emacs-config.md` | Emacs config work (.el files, `~/.config/emacs/`, emacs module dirs) |