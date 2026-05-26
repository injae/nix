---
name: nix-system
description: "Use at session start when NIX_CONFIG_DIR is set or flake.nix exists in cwd. Enforce Nix-managed config rules: never edit derived paths directly; edit sources under NIX_CONFIG_DIR."
user-invocable: true
---

# Nix System Configuration

Read sub-files from this skill base directory.

Rule: if `.envrc` exists in cwd, load and follow the `direnv` skill for environment-handling policy.

| File | When to Read |
|------|-------------|
| `rules.md` | Always |
| `claude-config.md` | Claude Code config work (skills, hooks, CLAUDE.md, settings.json, `~/.claude/`) |
| `emacs-config.md` | Emacs config work (.el files, `~/.config/emacs/`, emacs module dirs) |
