;;; +snippet.el --- Summery -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(use-package yasnippet :after f
:general (leader  "hy"  '(:wk "Yasnippet")
                  "hyl" 'consult-yasnippet)
:config
    (setq yas-snippet-dirs '("~/nixos-config/modules/shared/config/emacs/yas/"))
    (yas-global-mode t)
    (yas-reload-all t)

)

(use-package yasnippet-snippets :after yasnippet)

(use-package auto-yasnippet
;https://github.com/abo-abo/auto-yasnippet
:after yasnippet
:general (leader "hyc" 'aya-create
                 "hye" 'aya-expand)
)

(use-package consult-yasnippet)

(provide '+snippet)
;;; +snippet.el ends here
