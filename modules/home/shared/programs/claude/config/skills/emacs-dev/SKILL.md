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

1. Run `env | grep -E 'INSIDE_EMACS|TERM_PROGRAM'` via Bash.

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
