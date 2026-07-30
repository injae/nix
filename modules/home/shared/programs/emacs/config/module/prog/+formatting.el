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
    (setf (alist-get 'python-ts-mode    apheleia-mode-alist) '(ruff))
    (setf (alist-get 'go-ts-mode        apheleia-mode-alist) '(gofmt goimports))
    (setf (alist-get 'prettier-json     apheleia-formatters) '("prettier" "--stdin-filepath" filepath))
    ;; apheleia's builtin oxfmt uses `inplace', whose temp file lives outside the
    ;; project, so oxfmt fails to find .oxfmtrc.json. Use stdin instead.
    (setf (alist-get 'oxfmt             apheleia-formatters)
          '("apheleia-npx" "oxfmt" "--stdin-filepath" filepath))
    (dolist (mode '(js-ts-mode jsx-ts-mode typescript-ts-mode tsx-ts-mode
                    json-ts-mode css-ts-mode toml-ts-mode yaml-ts-mode
                    web-ts-mode vue-ts-mode markdown-mode))
        (setf (alist-get mode apheleia-mode-alist) '(oxfmt)))
    (apheleia-global-mode +1)
    )

;;(use-package caser)

(provide '+formatting)
;;; +formatting.el ends here

