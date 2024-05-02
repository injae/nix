;;; +nix.el --- Summery -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(use-package nix-mode :disabled
    :mode "\\.nix\\'"
    )

(use-package nix-ts-mode :after exec-path-from-shell
    :mode "\\.nix\\'"
    :hook (nix-ts-mode . lsp-deferred)
    :config (setq lsp-nix-nil-formatter ["nixpkgs-fmt"])
    )

(use-package sops
  :config (global-sops-mode)
  )

(provide '+nix)
;;; +nix.el ends here
