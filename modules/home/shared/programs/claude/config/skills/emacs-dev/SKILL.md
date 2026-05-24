---
name: emacs-dev
description: "Use when the task requires code navigation (LSP, xref, imenu), symbol lookup, file structure analysis, or Emacs Lisp development. Do NOT use for simple file edits, nix/config changes, or text questions."
user-invocable: false
allowed-tools:
  - ToolSearch
  - Read
---

# Emacs MCP Setup

Load MCP tool schemas via two parallel ToolSearch calls:
- `"emacs-tools"` max_results:29
- `"+ide getDiagnostics"` max_results:3

Then immediately **Read the sub-files** from this skill's base directory (shown above as "Base directory for this skill: ..."):

| File | When to Read |
|------|-------------|
| `navigation.md` | When task involves code navigation, LSP queries, symbol lookup, or cross-file analysis |
| `file-analysis.md` | Always — read immediately after loading MCP tools |
| `elisp.md` | When the task involves `.el` files or Emacs Lisp code — regardless of which file is currently open in the IDE |
| `testing.md` | When the user asks to validate, test, or evaluate navigation skills |

Read only the relevant sub-files based on the task. Reply: "Emacs mode active — MCP tools loaded."