;;; +ai.el --- Summery -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(use-package claude-code-ide :ensure (:repo "manzaltu/claude-code-ide.el" :host github)
    :config
    ;; Or switch back to vterm (default)
    (claude-code-ide-emacs-tools-setup)
    (setq claude-code-ide-terminal-backend 'vterm)
    (setq claude-code-ide-vterm-anti-flicker t)
    (setq claude-code-ide-vterm-render-delay 0.01)
)

(provide '+ai)
;;; +ai.el ends here
