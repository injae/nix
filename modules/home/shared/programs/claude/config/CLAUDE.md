# Global Claude Code Instructions

## Session start

At the start of every session:

1. Invoke the `emacs-dev` skill to check for Emacs environment and configure MCP tools.
2. Check whether `~/.claude/CLAUDE.local.md` exists via Bash. If it exists, read and apply its contents as additional instructions for this session.

## Elisp editing

When editing `.el` files, always verify parenthesis balance before finishing any edit — count `(` and `)` in every expression written.
