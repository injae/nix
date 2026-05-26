---
name: emacs-dev
description: "Use for code navigation, symbol/reference lookup, structural analysis, or Emacs Lisp development. Do not use for simple edits, nix/config changes, or text-only questions."
user-invocable: false
allowed-tools:
  - ToolSearch
  - Read
---

# Emacs MCP Setup

Load MCP tool schemas via two parallel ToolSearch calls:
- `"emacs-tools"` max_results:29
- `"+ide getDiagnostics"` max_results:3

Then read sub-files from this skill base directory:

| File | When to Read |
|------|-------------|
| `navigation.md` | Code navigation, LSP queries, symbol lookup, cross-file analysis |
| `file-analysis.md` | Always — read right after MCP tool load |
| `elisp.md` | Any `.el`/Emacs Lisp task, regardless of active IDE file |
| `testing.md` | When user asks to validate/test/evaluate navigation skills |

Read only task-relevant sub-files. Reply: "Emacs mode active — MCP tools loaded."
