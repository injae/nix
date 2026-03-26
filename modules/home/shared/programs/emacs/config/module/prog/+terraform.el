;;; +terraform.el --- Summery -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(use-package hcl-mode
    :mode   (("\\.hcl\\'" . hcl-mode)
             ("\\.alloy\\'" . hcl-mode))
    )

(use-package terraform-mode
    :mode   (("\\.tf\\'" . terraform-mode))
    :hook (terraform-mode . (lambda () (lsp)))
    :custom
    (terraform-indent-level 2)
    (lsp-terraform-enable-logging t)
    (lsp-terraform-ls-enable-show-reference t)
    ;; (lsp-semantic-tokens-enable t)
    ;; (lsp-semantic-tokens-honor-refresh-requests t)
    (lsp-enable-links t)
    (lsp-terraform-ls-prefill-required-fields t)
    (lsp-terraform-ls-validate-on-save t)
    ;; (lsp-register-client
    ;;     (make-lsp-client
    ;;         :new-connection (lsp-stdio-connection '("~/go/bin/terraform-ls" "serve"))
    ;;         :major-modes    '(terraform-mode)
    ;;         :server-id      'terraform-ls))
    )

(provide '+terraform)
;;; +terraform.el ends here
