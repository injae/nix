;;; +haskell.el --- Summery
;;; -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(use-package haskell-mode :after exec-path-from-shell
:mode ("\\.hs\\'"    . haskell-mode)
:hook ((haskell-mode          . my/eglot-ensure)
       (haskell-literate-mode . my/eglot-ensure))
)

(provide '+haskell)
;;; +haskell.el ends here
