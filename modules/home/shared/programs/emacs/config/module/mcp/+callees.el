;;; +callees.el --- MCP tool: list functions called by an Elisp function -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(defun claude-code-ide-mcp-elisp-callees (name)
  "Return all functions called by the Elisp function NAME.
Uses macro-expansion so indirect calls via macros are included."
  (condition-case err
      (let ((sym (intern-soft name)))
        (cond
         ((not sym)
          (format "Symbol '%s' not found." name))
         ((not (fboundp sym))
          (format "'%s' is not a function." name))
         (t
          (let* ((location (find-function-noselect sym t))
                 (buf (car location))
                 (pos (cdr location)))
            (if (not (and buf pos))
                (format "Cannot find source for '%s' (built-in or interactively defined)." name)
              (let* ((form
                      (with-current-buffer buf
                        (let ((inhibit-redisplay t))
                          (save-excursion
                            (goto-char pos)
                            (read (current-buffer))))))
                     (callees (helpful--callees form)))
                (if (null callees)
                    (format "'%s' does not call any other named functions." name)
                  (format "Functions called by '%s' (%d):\n%s"
                          name
                          (length callees)
                          (mapconcat #'symbol-name callees "\n")))))))))
    (error (format "Error finding callees for '%s': %s"
                   name (error-message-string err)))))

(claude-code-ide-make-tool
    :function #'claude-code-ide-mcp-elisp-callees
    :name "claude-code-ide-mcp-elisp-callees"
    :description "List all functions called by a given Elisp function. Performs macro-expansion before analysis, so indirect calls via macros are included. Equivalent to helpful's 'Functions used by' section. Only works with Elisp symbols."
    :args '((:name "name"
             :type string
             :description "The name of the Elisp function to inspect")))

(provide '+callees)
;;; +callees.el ends here
