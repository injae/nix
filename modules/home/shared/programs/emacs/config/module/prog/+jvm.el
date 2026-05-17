;;; +jvm.el --- Summery -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(use-package gradle-mode :config (add-hook 'java-mode-hook 'gradle-mode))
(use-package groovy-mode
:mode (".gradle\\'" . groovy-mode)
)

(use-package kotlin-mode :after exec-path-from-shell
:hook (kotlin-mode . my/eglot-ensure)
)


(provide '+jvm)
;;; +jvm.el ends here
