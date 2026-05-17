;;; +web.el --- Summery -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(use-package web-mode
    :mode (("\\.html?\\'"    . web-ts-mode)
           ("\\.xhtml$\\'"   . web-ts-mode)
           ("\\.phtml\\'"    . web-ts-mode)
           ("\\.erb\\'"      . web-ts-mode)
           ("\\.tpl\\'"      . web-ts-mode)
           ("\\.php\\'"      . web-ts-mode)
           ("\\.[agj]sp\\'"  . web-ts-mode)
           ("\\.as[cp]x\\'"  . web-ts-mode)
           ("\\.mustache\\'" . web-ts-mode)
           ("\\.djhtml\\'"   . web-ts-mode))
    :custom
    (web-mode-enable-engine-detection t)
    (sgml-basic-offset 2)
    (web-mode-markup-indent-offset 2)
    (web-mode-css-indent-offset 2)
    (web-mode-code-indent-offset 2)
    (web-mode-enable-auto-pairing t)
    (web-mode-enable-css-colorization t)
    ;:config (add-hook 'web-mode-hook #'lsp)
)

(use-package vue-ts-mode
    :ensure (:host github :repo "8uff3r/vue-ts-mode")
    :mode "\\.vue\\'"
    :hook (vue-ts-mode . my/eglot-ensure)
)

(use-package typescript-ts-mode :ensure nil :no-require t
    :mode (("\\.ts\\'"  . typescript-ts-mode)
           ("\\.tsx\\'" . tsx-ts-mode))
    :hook (typescript-ts-base-mode . my/eglot-ensure)
    :custom (typescript-indent-level 2)
            (typescript-ts-mode-indent-offset 2)
    )

(use-package js-mode :ensure nil :no-require t
    :mode (("\\.js\\'"  . js-ts-mode)
           ("\\.jsx\\'" . jsx-ts-mode))
    :custom (js-indent-level 2)
    )

(use-package css-mode :ensure nil :no-require t
    :mode ("\\.css\\'" . css-ts-mode)
    :custom (css-indent-offset 2)
    )

(use-package eglot-typescript-preset :after eglot
  :config (eglot-typescript-preset-setup)
  )

(provide '+web)
;;; +web.el ends here
