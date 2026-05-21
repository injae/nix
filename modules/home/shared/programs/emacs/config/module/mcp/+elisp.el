;;; +elisp.el --- MCP tools: Emacs Lisp file utilities -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(defun claude-code-ide-mcp-elisp-check-parens (file-path)
  "Check parenthesis balance of FILE-PATH using check-parens."
  (condition-case err
      (with-temp-buffer
        (insert-file-contents file-path)
        (condition-case e
            (progn (check-parens) "balanced")
          (error (error-message-string e))))
    (error (format "Error: %s" (error-message-string err)))))

(claude-code-ide-make-tool
    :function #'claude-code-ide-mcp-elisp-check-parens
    :name "claude-code-ide-mcp-elisp-check-parens"
    :description "Check parenthesis balance of an Emacs Lisp file using check-parens. Returns \"balanced\" or an error message with the mismatch location. Call after every edit to a .el file."
    :args '((:name "file_path"
             :type string
             :description "Absolute path to the .el file to check")))

(defun claude-code-ide-mcp-elisp-load-file (file-path)
  "Load FILE-PATH into the running Emacs session."
  (condition-case err
      (progn
        (load-file file-path)
        (format "Loaded: %s" file-path))
    (error (format "Error: %s" (error-message-string err)))))

(claude-code-ide-make-tool
    :function #'claude-code-ide-mcp-elisp-load-file
    :name "claude-code-ide-mcp-elisp-load-file"
    :description "Load an Emacs Lisp file into the running Emacs session via load-file. Use after editing a .el file to test changes interactively."
    :args '((:name "file_path"
             :type string
             :description "Absolute path to the .el file to load")))

(provide '+elisp)
;;; +elisp.el ends here