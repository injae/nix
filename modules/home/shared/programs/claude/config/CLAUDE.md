# Global Claude Instructions

## Session start

`SessionStart` hook injects env-specific skill/instructions:
- `INSIDE_EMACS` set → `/emacs-dev`
- `NIX_CONFIG_DIR` set → `/nix-system`
- `~/.claude/CLAUDE.local.md` exists → inject file content

## Language

Always respond in Korean.

## Work style

NEVER execute without approval. ALWAYS: plan → wait for explicit approval → execute. Skipping is not allowed.
