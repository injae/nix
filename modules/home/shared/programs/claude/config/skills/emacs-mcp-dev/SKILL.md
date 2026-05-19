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

## Checklist

- File naming: use the domain/function name, not the underlying package (e.g. `+formatting.el` not `+apheleia.el`)
- Naming: public `claude-code-ide-mcp-{verb}-{noun}`, private helpers `claude-code-ide-mcp--{name}`
- Wrap every public function body in `condition-case err`
- After creating the file, run `git add` (Nix flakes ignore untracked files)
- Verify parenthesis balance via `mcp__ide__executeCode`: `(with-temp-buffer (insert-file-contents "...") (condition-case e (progn (check-parens) "balanced") (error (error-message-string e))))`
