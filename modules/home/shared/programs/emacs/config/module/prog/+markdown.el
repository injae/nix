;;; +markdown.el --- Summery -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(use-package markdown-mode
:mode  (("\\README.md\\'" . gfm-mode)
        ("\\.md\\'"       . gfm-mode)
        ("\\.markdown\\'" . gfm-mode))
:general (leader "hm" '(:wk "Markdown"))
:config (setq markdown-command "multimarkdown")
)

(use-package markdown-preview-mode)
(use-package gh-md
:general (leader "hmr" 'gh-md-render-buffer)
)

(provide '+markdown)
;;; +markdown.el ends here
