---
name: emacs-dev
description: "Invoke when running inside Emacs (INSIDE_EMACS is set or TERM_PROGRAM=emacs). Detects the Emacs environment and loads MCP tool schemas for navigation and file analysis. Triggered automatically by the SessionStart hook when Emacs is detected."
user-invocable: true
allowed-tools:
  - Bash(env*)
  - ToolSearch
  - Read
---

# Emacs Environment Detection

Run: `env | grep -E 'INSIDE_EMACS|TERM_PROGRAM'`

**If `INSIDE_EMACS` is set OR `TERM_PROGRAM=emacs`:** load MCP tool schemas via two parallel ToolSearch calls:
- `"emacs-tools"` max_results:26
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