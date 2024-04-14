;;; +debug.el --- Summery -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

;; https://github.com/svaante/dape 
(use-package dape :disabled
    :hook
    ((kill-emacs . dape-breakpoint-save)
     (after-init . dape-breakpoint-load))
    :init
    :config
    (setq dape-buffer-window-arrangement 'right)
    (setq dape-cwd-fn 'projectile-project-root)
    (dape-breakpoint-global-mode)
    )


(provide '+debug)
;;; +debug.el ends here
