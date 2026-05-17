;;; +nix.el --- Summery -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(use-package nix-ts-mode :after exec-path-from-shell
    :mode ("\\.nix\\'" . nix-ts-mode)
    :hook (nix-ts-mode . my/eglot-ensure)
)

(use-package sops
  :config (global-sops-mode)
  )

(provide '+nix)
;;; +nix.el ends here
