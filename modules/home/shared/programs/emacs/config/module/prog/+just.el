;;; +just.el --- Summery -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(use-package just-mode :after exec-path-from-shell
    :mode ("\\.just\\'" . just-mode)
    )

(use-package justl :after just-mode
    :custom (justl-executable "just")
    )

(provide '+just)
;;; +just.el ends here
