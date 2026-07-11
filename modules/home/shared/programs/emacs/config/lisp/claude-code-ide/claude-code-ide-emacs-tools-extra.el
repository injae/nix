;;; claude-code-ide-emacs-tools-extra.el --- Extra MCP tools aggregator -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(defvar claude-code-ide--extras-files
  '("claude-code-ide-extra-buffer-info"
    "claude-code-ide-extra-describe-symbol"
    "claude-code-ide-extra-elisp"
    "claude-code-ide-extra-formatting"
    "claude-code-ide-extra-lsp-nav-position"
    "claude-code-ide-extra-lsp-nav-workspace"
    "claude-code-ide-extra-magit"
    "claude-code-ide-extra-navigation"
    "claude-code-ide-extra-search")
  "Extras files loaded by `claude-code-ide-reload-mcp-tools'.")

(let ((extras-dir (expand-file-name "extras" (file-name-directory
                                              (or load-file-name buffer-file-name)))))
  (add-to-list 'load-path extras-dir))

(dolist (f claude-code-ide--extras-files)
  (require (intern f)))

(defun claude-code-ide-reload-mcp-tools ()
  "Reset the MCP tool registry and force-reload all extras files.
Use this after `just switch' to apply tool changes without restarting Emacs.
Bypasses `require' caching by calling `load-file' directly."
  (interactive)
  (setq claude-code-ide-mcp-server-tools nil)
  (let ((dir (expand-file-name
              "extras"
              (file-name-directory
               (locate-library "claude-code-ide-emacs-tools-extra")))))
    (dolist (f claude-code-ide--extras-files)
      (load-file (expand-file-name (concat f ".el") dir))))
  (message "MCP tools reloaded: %d tools registered"
           (length claude-code-ide-mcp-server-tools)))

(provide 'claude-code-ide-emacs-tools-extra)
;;; claude-code-ide-emacs-tools-extra.el ends here