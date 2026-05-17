;;; +yaml.el --- yaml config
;;; Commentary:
;;; Code:

(use-package yaml-mode
    :mode   (("\\.yaml\\'" . yaml-ts-mode)
             ("\\.yml\\'"  . yaml-ts-mode))
    :hook   (yaml-ts-mode . my/eglot-ensure)
    :custom (yaml-indent-offset 2)
    )

(provide '+yaml)
;;; +yaml.el ends here
