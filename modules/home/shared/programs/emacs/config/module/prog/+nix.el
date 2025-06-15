;;; +nix.el --- Summery -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(use-package nix-mode)

(use-package nix-ts-mode :after exec-path-from-shell
    :mode "\\.nix\\'"
    :hook (nix-ts-mode . lsp-deferred)
    :custom (
      (lsp-nix-nil-auto-eval-inputs t)
      (lsp-nix-nil-formatter ["nixfmt"])
      )
    )

(use-package sops
  :config (global-sops-mode)
  )

(provide '+nix)
;;; +nix.el ends here
