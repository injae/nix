---
name: emacs-dev
description: "Use for code navigation, symbol/reference lookup, structural analysis, or Emacs Lisp development. Do not use for simple edits, nix/config changes, or text-only questions."
user-invocable: false
allowed-tools:
  - ToolSearch
  - Read
---

# Emacs MCP Setup

**CRITICAL: BLOCKING setup. MUST NOT read any source file or answer any code question until complete.**

## MANDATORY — Load MCP tool schemas

Run IN PARALLEL:
- `"emacs-tools"` max_results:29
- `"+ide getDiagnostics"` max_results:3

**Calling any Emacs MCP tool before this step is a violation.**

Reply: "Emacs mode active — MCP tools loaded."

## Companion skills (depend on MCP schemas above)

These activate via hook when relevant. MCP schemas MUST be loaded (Step above) before any of these can call emacs MCP tools.

| Skill | Activate when |
|-------|--------------|
| `emacs-file-analysis` | reading/inspecting any source file |
| `emacs-navigation` | LSP navigation, symbol lookup, finding references |
| `emacs-lisp-development` | editing `.el` files or Emacs Lisp tasks |