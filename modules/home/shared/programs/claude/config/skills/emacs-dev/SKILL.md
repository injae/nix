---
name: emacs-dev
description: "MUST invoke this skill at the very start of every session without exception. Detects whether Claude is running inside Emacs and configures MCP tools accordingly. This is a MANDATORY step — do NOT skip it, even if the session appears non-Emacs or the task seems unrelated. Triggers automatically on session start per CLAUDE.md instructions."
user-invocable: true
allowed-tools:
  - Bash(env*)
  - ToolSearch
  - Read
---

# Emacs Environment Detection

Run: `env | grep -E 'INSIDE_EMACS|TERM_PROGRAM'`

**If `INSIDE_EMACS` is set OR `TERM_PROGRAM=emacs`:** load MCP tool schemas via two parallel ToolSearch calls:
- `"emacs-tools"` max_results:25
- `"+ide getDiagnostics"` max_results:3

Then immediately **Read the sub-files** from this skill's base directory (shown above as "Base directory for this skill: ..."):

| File | When to Read |
|------|-------------|
| `navigation.md` | Always — read immediately after loading MCP tools |
| `file-analysis.md` | Always — read immediately after `navigation.md` |
| `elisp.md` | Only when the file being worked on is `.el` (major-mode `emacs-lisp-mode`) |
| `testing.md` | When the user asks to validate, test, or evaluate navigation skills |

Read `navigation.md` and `file-analysis.md` in parallel. Reply: "Emacs mode active — MCP tools loaded."

**Otherwise:** use standard Bash tools. Reply: "Not in Emacs — using standard Bash tools."