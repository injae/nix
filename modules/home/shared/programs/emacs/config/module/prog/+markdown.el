;;; +markdown.el --- Summery -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(use-package markdown-mode)

(use-package markdown-ts-mode :ensure nil
    :mode ("\\.md\\'" . markdown-ts-mode)
    :hook (markdown-ts-mode . my/eglot-ensure)
    :custom (eglot-documentation-renderer 'markdown-ts-view-mode)
    )

(provide '+markdown)
;;; +markdown.el ends here
