---
name: nix-system
description: "Invoke at session start when NIX_CONFIG_DIR is set or when both .envrc and flake.nix are present in the working directory. Applies Nix-managed configuration rules: never edit derived paths directly, locate sources under NIX_CONFIG_DIR, and prefix shell commands with direnv exec when a flake devshell is active."
user-invocable: true
---

# Nix System Configuration

Read sub-files from this skill's base directory:

| File | When to Read |
|------|-------------|
| `rules.md` | Always |
| `claude-config.md` | When working on Claude Code config (skills, hooks, CLAUDE.md, settings.json, `~/.claude/`) |
| `emacs-config.md` | When working on Emacs config (.el files, `~/.config/emacs/`, emacs module dirs) |
