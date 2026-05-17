;;; +gleam.el --- Summery -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(use-package gleam-ts-mode :after exec-path-from-shell
    :mode (rx ".gleam" eos)
    :hook (gleam-ts-mode . my/eglot-ensure)
    :config (add-to-list 'eglot-server-programs '(gleam-ts-mode . ("gleam" "lsp")))
    )

(provide '+gleam)
;;; +gleam.el ends here
