;;; +config-file.el --- Summery -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(use-package cmake-mode :after exec-path-from-shell
;:ensure-system-package (cmake-language-server . "pip3 install cmake-language-server")
:mode (("\\.cmake\\'"    . cmake-ts-mode)
       ("CMakeLists.txt" . cmake-ts-mode))
:custom (cmake-tab-width 4)
:hook (cmake-mode . my/eglot-ensure)
)

(use-package dotenv-mode
    :mode (("\\.env\\..*\\'" . dotenv-mode)
           ("\\.envrc\\'"    . dotenv-mode)))

(use-package protobuf-mode :mode "\\.proto\\'")
(use-package plantuml-mode :mode "\\.plantuml\\'")

(provide '+config-file)
;;; +config-file.el ends here
