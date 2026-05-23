;;; claude-code-ide-emacs-tools-extra.el --- Extra MCP tools aggregator -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(let ((extras-dir (expand-file-name "extras" (file-name-directory
                                              (or load-file-name buffer-file-name)))))
  (add-to-list 'load-path extras-dir))

(require 'claude-code-ide-extra-buffer-info)
(require 'claude-code-ide-extra-call-function)
(require 'claude-code-ide-extra-describe-symbol)
(require 'claude-code-ide-extra-elisp)
(require 'claude-code-ide-extra-formatting)
(require 'claude-code-ide-extra-lsp-navigation)
(require 'claude-code-ide-extra-magit)
(require 'claude-code-ide-extra-navigation)

(provide 'claude-code-ide-emacs-tools-extra)
;;; claude-code-ide-emacs-tools-extra.el ends here