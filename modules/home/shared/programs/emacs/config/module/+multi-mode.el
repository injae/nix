;;; +multi-mode.el --- Summery -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(use-package polymode)

(use-package poly-org
    :hook (org-mode . poly-org-mode)
    )

(use-package poly-jetbrain-lua :no-require t :after polymode :ensure nil
:config
    ; jetbrain golang lua mode
    (define-hostmode poly-golang-lua-hostmode :mode 'go-ts-mode)
    (define-innermode poly-golang-lua-innermode
        :mode 'lua-ts-mode
        :head-matcher "// language=lua\n.*`$"
        :tail-matcher "^`$"
        ;:mode-matcher (cons "")
        :head-mode 'host
        :tail-mode 'host
        )
    (define-polymode poly-golang-lua-mode
        :hostmode   'poly-golang-lua-hostmode
        :innermodes '(poly-golang-lua-innermode))
)

(provide '+multi-mode)
;;; +multi-mode.el ends here
