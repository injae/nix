---
name: emacs-dev
description: "Use for code navigation, symbol/reference lookup, structural analysis, or Emacs Lisp development. Do not use for simple edits, nix/config changes, or text-only questions."

---

# Emacs MCP Setup

**CRITICAL: BLOCKING setup. MUST NOT read any source file or answer any code question until complete.**

## MANDATORY — Load MCP tool schemas

Run IN PARALLEL:
- `"emacs-tools"` max_results:100
- `"+ide getDiagnostics"` max_results:3

**Calling any Emacs MCP tool before this step is a violation.**

Reply: "Emacs mode active — MCP tools loaded."

## MANDATORY — Load companion skills immediately after MCP schemas

Invoke this NOW — not lazily, not "when needed":

1. `/skill:emacs-file-analysis` — governs ALL file reading (source AND config/go.mod/text files). Without this loaded, you will default to Bash grep.
2. `/skill:emacs-navigation` — load immediately when the task involves **any source file exploration** (reading multiple files, understanding codebase structure, migration, refactor). Do NOT wait until the first grep — by then the protocol is already violated.

**Do NOT defer. Load before touching any file or answering any code question.**

## Companion skills reference

| Skill | When to load | Covers |
|-------|-------------|--------|
| `emacs-file-analysis` | **session start (mandatory)** | ANY file read — source, go.md, config, text |
| `emacs-navigation` | **load before any source file exploration** — multiple file reads, codebase analysis, migration, refactor. Not needed for config/text-only tasks. | symbol lookup, reference search, definition jump, Bash grep/find replacement |
| `emacs-lisp-development` | on demand | `.el` file edits, Emacs Lisp tasks |