;;; +terraform.el --- Summery -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(use-package hcl-mode
    :mode   (("\\.hcl\\'" . hcl-mode)
             ("\\.alloy\\'" . hcl-mode))
    )

(use-package terraform-mode :after exec-path-from-shell
    :mode   (("\\.tf\\'" . terraform-mode))
    :hook (terraform-mode . my/eglot-ensure)
    :custom (terraform-indent-level 2)
    )

(provide '+terraform)
;;; +terraform.el ends here
