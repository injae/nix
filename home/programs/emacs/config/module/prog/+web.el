;;; +web.el --- Summery -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(use-package web-mode
;:commands (web-mode)
    :mode (("\\.html?\\'"  . web-mode)
           ("\\.xhtml$\\'" . web-mode)
           ("\\.phtml\\'" . web-mode)
           ("\\.erb\\'" . web-mode)
           ("\\.tpl\\.php\\'" . web-mode)
           ("\\.[agj]sp\\'" . web-mode)
           ("\\.as[cp]x\\'" . web-mode)
           ("\\.mustache\\'" . web-mode)
           ("\\.djhtml\\'" . web-mode)
           ("\\.vue\\'" . web-mode))
    :custom
    (web-mode-enable-engine-detection t)
        ;(web-mode-content-types-alist '(("jsx" . "\\.js[x]?\\'")))
        ;(add-hook 'web-mode-hook
        ;    (lambda ()
        ;        (when (string-equal "tsx" (file-name-extension buffer-file-name)
        ;                  (setup-tide-mode)))))
    (flycheck-add-mode 'typescript-tslint 'web-mode 'jsx-tide)
    :config
    (setq web-mode-markup-indent-offset 2)
    (setq web-mode-css-indent-offset 2)
    (setq web-mode-code-indent-offset 2)
    (setq web-mode-enable-auto-pairing t)
    (setq web-mode-enable-css-colorization t)
    (add-hook 'web-mode-hook #'lsp)
    (add-hook 'web-mode-hook (lambda () (my-set-indent 2)))
)

(use-package js2-mode
    :mode (("\\.js\\'"  . js2-mode)
           ("\\.mjs\\'" . js2-mode))
    :hook (js2-mode . (lambda () (my-set-indent 2) (lsp)))
)

(use-package xref-js2
    :after (js2-mode xref)
    :config
    (add-hook 'js2-mode-hook (lambda () (add-hook 'xref-backend-functions #'xref-js2-xref-backend nil t)))
)

(use-package lsp-tailwindcss :ensure (:type git :host github :repo "merrickluo/lsp-tailwindcss")
    :init (setq lsp-tailwindcss-add-on-mode t)
    :config
      (dolist (tw-major-mode
               '(css-mode
                 css-ts-mode
                 typescript-mode
                 typescript-ts-mode
                 tsx-ts-mode
                 js2-mode
                 js-ts-mode
                 clojure-mode))
        (add-to-list 'lsp-tailwindcss-major-modes tw-major-mode))
    )

(use-package typescript-ts-mode :ensure nil :no-require t
    :hook (typescript-ts-base-mode .
              (lambda ()
                  (require 'lsp-eslint)
                  (require 'lsp-tailwindcss)
                  (my-set-indent 2)
                  (lsp-deferred)))
    :mode (("\\.ts\\'"  . typescript-ts-mode)
           ("\\.tsx\\'" . tsx-ts-mode))
    )

(use-package tide
:after (typescript-ts-mode flycheck)
:hook  ((typescript-ts-base-mode . tide-setup)
        (typescript-ts-base-mode . tide-hl-identifier-mode)
        (before-save . tide-format-before-save))
)

;(use-package vue-mode
;    ;; install lsp-volar-* and typescript (npm install -g typescript)
;    :mode "\\.vue\\'"
;    :hook (vue-mode . prettier-js-mode)
;    :config (add-hook 'vue-mode-hook #'lsp)
;            (setq prettier-js-mode '("--parser vue"))
;)

(use-package prettier-js
:hook (js2-mode . prettier-js-mode)
      (typescript-ts-base-mode . prettier-js-mode)
      (web-mode . prettier-js-mode)
)

(provide '+web)
;;; +web.el ends here
