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

(use-package apheleia :after (exec-path-from-shell projectile)
    :preface
    (defun ij/fix-apheleia-project-dir (orig-fn &rest args)
        (let ((project (project-current)))
        (if (not (null project))
            (let ((default-directory (project-root project))) (apply orig-fn args))
            (apply orig-fn args))))
    :defines
      apheleia-mode-alist
      apheleia-formatters
    :functions
      apheleia-global-mode
    :config
    (advice-add 'apheleia-format-buffer :around #'ij/fix-apheleia-project-dir)
    (setf
      (alist-get 'python-mode   apheleia-mode-alist) '(ruff)
      (alist-get 'prettier-json apheleia-formatters) '("prettier" "--stdin-filepath" filepath)
      )
    (apheleia-global-mode +1)
    )

;;(use-package caser)

(provide '+formatting)
;;; +formatting.el ends here

