;;; +gleam.el --- Summery -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(use-package gleam-ts-mode
    :mode (rx ".gleam" eos)
    :hook (gleam-ts-mode . lsp-deferred)
    )

(provide '+gleam)
;;; +gleam.el ends here
