;;; +toml.el --- Summery -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(use-package toml-mode
    :mode   (("\\.toml\\'" . toml-ts-mode))
    :hook   (toml-ts-mode  . my/eglot-ensure)
    :custom (toml-indent-offset 2)
)

(provide '+toml)
;;; +toml.el ends here
