;;; +nix.el --- Summery -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(use-package nix-mode)

(use-package nix-ts-mode :after exec-path-from-shell
    :mode "\\.nix\\'"
    :hook (nix-ts-mode . lsp-deferred)
    :custom
      (lsp-nix-nil-auto-eval-inputs t)
      (lsp-nix-nil-formatter ["nixfmt"])
      ;(lsp-disabled-clients '((nix-mode . nix-nil))) ;; Disable nil so that nixd will be used as lsp-server
    :config
    (setq
        lsp-nix-nixd-server-path "nixd"
        lsp-nix-nixd-formatting-command [ "nixfmt" ]
        lsp-nix-nixd-nixpkgs-expr "import <nixpkgs> { }"
        lsp-nix-nixd-nixos-options-expr "(builtins.getFlake \"/Users/nieel/nix\").darwinConfigurations.nieel-m3.options"
    ;    lsp-nix-nixd-home-manager-options-expr "(builtins.getFlake \"/User/nieel/nix\").darwinConfigurations.nieel-m3.options.home-manager.users.type.getSubOptions"
    )
)

(use-package sops
  :config (global-sops-mode)
  )

(provide '+nix)
;;; +nix.el ends here
