;;; +markdown.el --- Summery -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(use-package markdown-mode)


(use-package markdown-ts-mode
    :mode ("\\.md\\'" . markdown-ts-mode)
    :hook (markdown-ts-mode . my/eglot-ensure))

(provide '+markdown)
;;; +markdown.el ends here
