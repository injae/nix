;;; claude-code-ide-extra-navigation.el --- MCP tools: file and line navigation -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(require 'claude-code-ide-mcp-server)

(defun claude-code-ide-mcp-goto-file-line (file-path line)
  "Open FILE-PATH at LINE in the primary code window (non-claude, non-magit)."
  (condition-case err
      (let* ((code-window
              (or (seq-find
                   (lambda (w)
                     (let ((name (buffer-name (window-buffer w))))
                       (and (not (string-match-p "\\*claude-code" name))
                            (not (string-match-p "^magit" name))
                            (not (string-prefix-p " " name))
                            (not (string-match-p "^\\*" name)))))
                   (window-list))
                  (seq-find
                   (lambda (w)
                     (not (string-match-p "\\*claude-code"
                                          (buffer-name (window-buffer w)))))
                   (window-list))
                  (selected-window))))
        (with-selected-window code-window
          (find-file file-path)
          (goto-char (point-min))
          (forward-line (1- line))
          (recenter 5)
          (format "Opened %s at line %d" file-path line)))
    (error (format "Error: %s" (error-message-string err)))))

(claude-code-ide-make-tool
    :function #'claude-code-ide-mcp-goto-file-line
    :name "goto-line"
    :description "Open file at line in primary code window (non-claude, non-magit). Target near top. Focus user view."
    :args '((:name "file_path"
             :type string
             :description "Absolute path to file")
            (:name "line"
             :type number
             :description "Line (1-based)")))

(defun claude-code-ide-mcp-open-file-lsp (file-path)
  "Open FILE-PATH in Emacs and start LSP server without interactive prompts.
Uses eglot--connect directly since eglot-ensure relies on post-command-hook
and never fires in non-interactive (MCP) contexts."
  (condition-case err
      (let* ((expanded (expand-file-name file-path))
             (buf (or (find-buffer-visiting expanded)
                      (find-file-noselect expanded))))
        (with-current-buffer buf
          (unless (eglot-current-server)
            (condition-case oops
                (apply #'eglot--connect (eglot--guess-contact))
              (error (message "[open-file-lsp] eglot--connect: %s" (error-message-string oops)))))
          (cl-loop repeat 100
                   until (eglot-current-server)
                   do (sleep-for 0.1))
          (if (eglot-current-server)
              (format "LSP ready: %s" expanded)
            (format "LSP not ready for %s — server may need more time or is unsupported" expanded))))
    (error (format "Error: %s" (error-message-string err)))))

(claude-code-ide-make-tool
    :function #'claude-code-ide-mcp-open-file-lsp
    :name "open-file-lsp"
    :description "Open file in Emacs and start LSP server without UI prompts. Call before lsp-* tools on projects not yet open in Emacs."
    :args '((:name "file_path"
             :type string
             :description "Absolute path to any file in the project")))

(provide 'claude-code-ide-extra-navigation)
;;; claude-code-ide-extra-navigation.el ends here
