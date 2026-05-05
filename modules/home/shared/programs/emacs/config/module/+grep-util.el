;;; +grep-util.el --- Summery -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(use-package rg :after general
     :general (leader "fg" 'rg-menu)
     :config
     (rg-enable-default-bindings)
     (advice-add 'wgrep-change-to-wgrep-mode :after #'evil-normal-state)
     (advice-add 'wgrep-to-original-mode     :after #'evil-motion-state)
     (defvar rg-mode-map)
     (add-to-list 'evil-motion-state-modes 'rg-mode)
     (evil-add-hjkl-bindings rg-mode-map `motion
         "e" #'wgrep-change-to-wgrep-mode
         "g" #'rg-recompile
         "t" #'rg-rerun-change-literal)
)

(use-package wgrep :after rg
:config (setq wgrep-auto-save-buffer t)
)

(provide '+grep-util)
;;; +grep-util.el ends here
