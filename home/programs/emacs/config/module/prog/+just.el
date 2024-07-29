;;; +just.el --- Summery -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(use-package just-mode :after exec-path-from-shell)

(use-package justl :after just-mode
    :custom (justl-executable "just")
    )

(provide '+just)
;;; +just.el ends here
