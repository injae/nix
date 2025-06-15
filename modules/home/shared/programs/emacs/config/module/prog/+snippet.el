;;; +snippet.el --- Summery -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(use-package yasnippet
:general (leader  "hy"  '(:wk "Yasnippet"))
:config
    (setq yas-snippet-dirs
        (list (f-join user-mutable-emacs-directory "config/yas")))
    (yas-global-mode t)
    (yas-reload-all t)
)

(use-package yasnippet-snippets :after yasnippet)

(use-package auto-yasnippet :after yasnippet
;https://github.com/abo-abo/auto-yasnippet
:general (leader "hyc" 'aya-create
                 "hye" 'aya-expand)
)

(use-package consult-yasnippet :after yasnippet
    :general (leader "hyl" 'consult-yasnippet)
    )

(provide '+snippet)
;;; +snippet.el ends here
