;;; +ai.el --- Summery -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(use-package claude-code-ide :ensure (:repo "manzaltu/claude-code-ide.el" :host github)
    :general (leader "a" '(claude-code-ide-menu :wk "Claude Code IDE Menu"))
    :custom
    (claude-code-ide-open-in-new-frame t)
    (claude-code-ide-enable-mcp-server t)
    (claude-code-ide-terminal-backend 'vterm)
    (claude-code-ide-vterm-anti-flicker t)
    (claude-code-ide-vterm-render-delay 0.01)
    :config
    (claude-code-ide-emacs-tools-setup)
    (load-modules-with-list
        (f-join user-emacs-module-directory "mcp")
        '(describe-symbol find-references callees lsp-key-map call-function buffer-info formatting)))

(provide '+ai)
;;; +ai.el ends here
