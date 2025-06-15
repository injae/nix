;;; +markdown.el --- Summery -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(use-package markdown-mode
:after poly-markdown
:mode  (("\\README.md\\'" . gfm-mode)
        ("\\.md\\'"       . gfm-mode)
        ("\\.markdown\\'" . gfm-mode))
:general (leader "hm" '(:wk "Markdown"))
:config (setq markdown-command "multimarkdown")
        (poly-markdown-mode)
)

(use-package markdown-preview-mode  :defer t)
(use-package gh-md   :defer t
:general (leader "hmr" 'gh-md-render-buffer)
)

(provide '+markdown)
;;; +markdown.el ends here
