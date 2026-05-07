;;; +python.el --- Summery -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(use-package python-mode :after exec-path-from-shell
    :mode (("\\.py\\'" . python-ts-mode)
           ("\\.wsgi$" . python-ts-mode))
    :custom ((python-indent-preset 4)
             (python-indent-block-paren-deeper t))
    )

(use-package python-pytest)

(use-package eglot-python-preset :after eglot
    :custom (eglot-python-preset-lsp-server 'rass)
    :config (setopt eglot-python-preset-rass-tools '(ty ruff))
    )

(use-package pet :after python
    :config
    (add-hook 'python-base-mode-hook 'pet-mode -10)
    (add-hook 'python-base-mode-hook (lambda ()
        (setq-local python-shell-interpreter     (pet-executable-find "python")
                    python-shell-virtualenv-root (pet-virtualenv-root))
        (my/eglot-ensure)
        ))
    )

(use-package flymake-ruff :after (python eglot) :disabled
    :hook (python-base-mode . flymake-ruff-load))

(use-package jinja2-mode)

(use-package jupyter :disabled)

(provide '+python)
;;; +python.el ends here
