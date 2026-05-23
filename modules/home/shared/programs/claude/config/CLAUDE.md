# Global Claude Code Instructions

## Session start

Environment-specific skills are triggered automatically by the `SessionStart` hook:
- **Emacs** (`INSIDE_EMACS` set) → `/emacs-dev` skill injected
- **Nix** (`NIX_CONFIG_DIR` set) → `/nix-system` skill injected
- **`~/.claude/CLAUDE.local.md`** exists → its contents are injected as additional instructions

## Language

Always respond in Korean.

## Work style

Before starting any task, always explain the planned steps first, then proceed.