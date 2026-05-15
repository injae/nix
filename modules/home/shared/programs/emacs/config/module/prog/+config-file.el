;;; +config-file.el --- Summery -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(use-package yaml-mode
:mode (("\\.yaml\\'" . yaml-ts-mode)
       ("\\.yml\\'"  . yaml-ts-mode))
:hook (yaml-ts-mode  . my/eglot-ensure)
)

(use-package toml-mode
:mode (("\\.toml\\'" . toml-mode)
       ("Pipfile\\'" . toml-mode))
)

(use-package cmake-mode
;:ensure-system-package (cmake-language-server . "pip3 install cmake-language-server")
:commands cmake-mode
:mode (("\\.cmake\\'"    . cmake-mode)
       ("CMakeLists.txt" . cmake-mode))
:custom (cmake-tab-width 4)
:hook (cmake-mode . (lambda () (require 'lsp-cmake) (lsp)))
)

(use-package dotenv-mode
    :mode (("\\.env\\..*\\'" . dotenv-mode)
           ("\\.envrc\\'" . dotenv-mode)))

(use-package protobuf-mode :mode "\\.proto\\'")
(use-package plantuml-mode :mode "\\.plantuml\\'")

(provide '+config-file)
;;; +config-file.el ends here
