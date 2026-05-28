---
name: emacs-mcp-dev
description: "Guide for adding new Emacs MCP tools to the claude-code-ide setup. Use when asked to create, modify, or debug MCP tools in config/lisp/claude-code-ide/extras/."
user-invocable: true
---

# Adding New Emacs MCP Tools

Tools live in `config/lisp/claude-code-ide/extras/`, one file per domain:

| File | Domain |
|------|--------|
| `claude-code-ide-extra-buffer-info.el` | buffer info, file outline, symbol source |
| `claude-code-ide-extra-call-function.el` | call any Elisp function by name |
| `claude-code-ide-extra-describe-symbol.el` | describe function/variable |
| `claude-code-ide-extra-elisp.el` | callees, load-file, find-references |
| `claude-code-ide-extra-formatting.el` | apheleia formatter |
| `claude-code-ide-extra-lsp-nav-position.el` | LSP position-based navigation (def, refs, impl, type) |
| `claude-code-ide-extra-lsp-nav-workspace.el` | LSP workspace/symbol navigation |
| `claude-code-ide-extra-magit.el` | magit git operations |
| `claude-code-ide-extra-navigation.el` | goto-line |

`claude-code-ide-emacs-tools-extra.el` is the aggregator — it adds `extras/` to `load-path` and `require`s each file. No registration step needed beyond adding to the right file.

## Adding a tool

**To an existing domain**: append the function and `claude-code-ide-make-tool` call to the matching `extras/` file.

**New domain**: create `extras/claude-code-ide-extra-{domain}.el` and add a `require` line to `claude-code-ide-emacs-tools-extra.el`.

```elisp
;;; claude-code-ide-extra-{domain}.el --- MCP tools: {description} -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(require 'claude-code-ide-mcp-server)

;; private helpers use double-dash: claude-code-ide-mcp--{name}
;; public tools use single-dash:   claude-code-ide-mcp-{verb}-{noun}

(defun claude-code-ide-mcp-{verb}-{noun} (arg)
  "Docstring."
  (condition-case err
      (... implementation ...)
    (error (format "Error: %s" (error-message-string err)))))

(claude-code-ide-make-tool
    :function #'claude-code-ide-mcp-{verb}-{noun}
    :name "{verb}-{noun}"
    :description "..."
    :args '((:name "arg" :type string :description "...")))

(provide 'claude-code-ide-extra-{domain})
;;; claude-code-ide-extra-{domain}.el ends here
```

## Tool `:name` convention

Use short **hyphen-case** names — not the full `claude-code-ide-mcp-` prefix. Examples:

| Elisp function | `:name` |
|----------------|---------|
| `claude-code-ide-mcp-lsp-find-definition` | `"lsp-def"` |
| `claude-code-ide-mcp-goto-file-line` | `"goto-line"` |
| `claude-code-ide-mcp-format-buffer` | `"format-buffer"` |

The Elisp function name keeps the full prefix; only the MCP `:name` (what Claude sees) is shortened.

When referencing emacs-tools in skill documents, always use the shorthand name (e.g., `` `goto-line` ``, `` `format-buffer` ``) — never the full `mcp__emacs-tools__` prefix. The exception is `allowed-tools` frontmatter, where the full identifier is required by the Claude Code permission system.

## Force-reload (runtime update without restart)

After editing an extras file, call `M-x claude-code-ide-reload-mcp-tools` to apply changes immediately. This resets `claude-code-ide-mcp-server-tools` and force-reloads every extras file via `load-file`, bypassing `require` caching.

> **Why `require` alone is not enough**: `require` is a no-op if the feature symbol is already provided. `load-file` always re-evaluates the file, re-running `claude-code-ide-make-tool` calls with updated `:name` values.

Claude Code's ToolSearch reflects session-start state — new names only appear after starting a new session. The tools themselves work immediately after reload.

## After adding a tool

Update `emacs-dev/SKILL.md`:
- `max_results` in the ToolSearch query `"emacs-tools"` must be ≥ total number of registered `mcp__emacs-tools__*` tools. Count tools in `+ai.el` and set accordingly.
- If the new tool is useful for code navigation, add it to the Code navigation table with its signature and fallback.

## LSP navigation tools

When adding LSP navigation tools, read `mcp-tool-patterns.md` (in this skill's directory) first. It documents the three established patterns:

| Pattern | When to use |
|---------|------------|
| **A — Position-based** (`--at-position`) | tool takes file + line + col |
| **B — Identifier-based** (`--with-identifier`) | tool takes a symbol name string |
| **C — Server-context search** (`server-with-session-context`) | tool queries LSP workspace/symbol |

Pattern C has a known pitfall: one misplaced `)` absorbs the `condition-case` error handler into the macro body, leaving no handler. After writing any Pattern C tool, run the Step 4.5 diagnostic in `mcp-tool-patterns.md`.

## Background operation — don't disturb the user

MCP tools that read files or navigate buffers must **not** cause visible screen updates. Two categories:

### Read-only tools (find-definition, find-references, formatter-info, …)

Always wrap the **entire** function body — including `find-file-noselect` — with `(let ((inhibit-redisplay t)) ...)`. If `inhibit-redisplay` is set only *inside* `with-current-buffer`, it is too late: `find-file-noselect` will already have run mode hooks that can cause flicker.

**Wrong** — protection starts after `find-file-noselect`:
```elisp
(with-current-buffer (or (find-buffer-visiting file-path)
                         (find-file-noselect file-path))   ; hooks fire unprotected
  (let ((inhibit-redisplay t))
    (save-excursion ...)))
```

**Correct** — protection wraps everything:
```elisp
(let ((inhibit-redisplay t))                               ; blocks hooks & redisplay
  (with-current-buffer (or (find-buffer-visiting file-path)
                           (find-file-noselect file-path))
    (save-excursion ...)))
```

Also always pair buffer navigation with `save-excursion` so the buffer point is restored after the tool runs.

### Write / navigation tools (goto-line, git-prepare-commit, format-buffer)

These are **intentionally foreground**: they change what the user sees (`find-file` + `recenter`) or open a new buffer (commit editor). Do **not** add `inhibit-redisplay` to these — they need to update the display.

## Checklist

- Add to the matching `extras/claude-code-ide-extra-{domain}.el` (or create a new file + `require` in the aggregator)
- Naming: public `claude-code-ide-mcp-{verb}-{noun}`, private helpers `claude-code-ide-mcp--{name}`
- Wrap every public function body in `condition-case err`
- Read-only tools: `(let ((inhibit-redisplay t)) ...)` **outside** `with-current-buffer` / `find-file-noselect`
- Read-only tools: `save-excursion` inside every buffer navigation block
- Verify parenthesis balance via Bash: `python3 ~/.claude/hooks/elisp-check-parens.py <file_path>`
- Pattern C tools: run the Step 4.5 diagnostic from `mcp-tool-patterns.md` after writing — one misplaced `)` silently disables the `condition-case` handler
