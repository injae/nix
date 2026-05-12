;;; +formatting.el --- Summery -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(use-package format-all :after exec-path-from-shell :disabled
    :hook ((prog-mode . format-all-mode)
           (format-all-mode . format-all-ensure-formatter))
                                        ;:custom (format-all-formatters
                                        ;            '(("Python"
                                        ;                  ("ruff" "check" ".")
                                        ;                  ("ruff" "format" "."))))
    )

(use-package apheleia :after (exec-path-from-shell)
    :config
    (setf (alist-get 'python-ts-mode   apheleia-mode-alist) '(ruff))
    (setf (alist-get 'go-ts-mode       apheleia-mode-alist) '(gofmt goimports))
    (setf (alist-get 'prettier-json apheleia-formatters) '("prettier" "--stdin-filepath" filepath))
    (apheleia-global-mode +1)
    )

;;(use-package caser)

(provide '+formatting)
;;; +formatting.el ends here

