---
name: emacs-mcp-dev
description: "Guide for adding new Emacs MCP tools to the claude-code-ide setup. Use when asked to create, modify, or debug MCP tools in config/module/mcp/."
user-invocable: true
---

# Adding New Emacs MCP Tools

Tools live in `config/module/mcp/+{name}.el` and are registered in `config/module/+ai.el`.

## File structure

```elisp
;;; +{name}.el --- MCP tools: {description} -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

;; private helpers use double-dash: claude-code-ide-mcp--{name}
;; public tools use single-dash:   claude-code-ide-mcp-{verb}-{noun}

(defun claude-code-ide-mcp-{verb}-{noun} (arg)
  "Docstring."
  (condition-case err
      (... implementation ...)
    (error (format "Error: %s" (error-message-string err)))))

(claude-code-ide-make-tool
    :function #'claude-code-ide-mcp-{verb}-{noun}
    :name "claude-code-ide-mcp-{verb}-{noun}"
    :description "..."
    :args '((:name "arg" :type string :description "...")))

(provide '+{name})
;;; +{name}.el ends here
```

## Registering the tool

Add the symbol to the list in `config/module/+ai.el`:

```elisp
(load-modules-with-list
    (f-join user-emacs-module-directory "mcp")
    '(... existing ... {name}))
```

## After adding a tool

Update `emacs-dev/SKILL.md`:
- `max_results` in the ToolSearch query `"emacs-tools"` must be ≥ total number of registered `mcp__emacs-tools__*` tools. Count tools in `+ai.el` and set accordingly.
- If the new tool is useful for code navigation, add it to the Code navigation table with its signature and fallback.

## LSP navigation tools (`+lsp-navigation.el`)

When adding tools to `+lsp-navigation.el` specifically, read `mcp-tool-patterns.md` (in this skill's directory) first. It documents the three established patterns:

| Pattern | When to use |
|---------|------------|
| **A — Position-based** (`--at-position`) | tool takes file + line + col |
| **B — Identifier-based** (`--with-identifier`) | tool takes a symbol name string |
| **C — Server-context search** (`server-with-session-context`) | tool queries LSP workspace/symbol |

Pattern C has a known pitfall: one misplaced `)` absorbs the `condition-case` error handler into the macro body, leaving no handler. After writing any Pattern C tool, run the Step 4.5 diagnostic from `emacs-dev/elisp.md`.

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

### Write / navigation tools (goto-file-line, magit-prepare-commit, format-buffer)

These are **intentionally foreground**: they change what the user sees (`find-file` + `recenter`) or open a new buffer (commit editor). Do **not** add `inhibit-redisplay` to these — they need to update the display.

## Checklist

- File naming: use the domain/function name, not the underlying package (e.g. `+formatting.el` not `+apheleia.el`)
- Naming: public `claude-code-ide-mcp-{verb}-{noun}`, private helpers `claude-code-ide-mcp--{name}`
- Wrap every public function body in `condition-case err`
- Read-only tools: `(let ((inhibit-redisplay t)) ...)` **outside** `with-current-buffer` / `find-file-noselect`
- Read-only tools: `save-excursion` inside every buffer navigation block
- Verify parenthesis balance via `mcp__ide__executeCode`: `(with-temp-buffer (insert-file-contents "...") (condition-case e (progn (check-parens) "balanced") (error (error-message-string e))))`
