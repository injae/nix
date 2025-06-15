;;; +python.el --- Summery -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(use-package python-mode :after exec-path-from-shell
    :mode (("\\.py\\'" . python-ts-mode)
           ("\\.wsgi$" . python-ts-mode))
    ;:ensure-system-package ((pylint . "pip install pylint pylint-strict-informational")
    ;                        (mypy   . "pip install mypy")
    ;                        (flake8 . "pip install flake8")
    ;                        (isort . "pip install isort")
    ;                        (black . "pip install black")
    ;                           )
    :custom (python-indent-offset 4)
    ;; :config
    ;; (setq python-ts-mode-hook python-mode-hook)
    )

(use-package python-pytest)

(use-package pet :after python
    :config
    (add-hook 'python-base-mode-hook 'pet-mode -10)
    (add-hook 'python-base-mode-hook (lambda ()
        (setq-local python-shell-interpreter (pet-executable-find "python")
                    python-shell-virtualenv-root (pet-virtualenv-root))
        (pet-flycheck-setup)
        (setq-local lsp-pyright-python-executable-cmd python-shell-interpreter
                    lsp-pyright-venv-path python-shell-virtualenv-root)

        (require 'lsp-pyright)
        (require 'lsp-ruff)
        (lsp-deferred)
        (setq-local dap-python-executable python-shell-interpreter)
        ))

    )

(use-package flymake-ruff :after (python eglot) :disabled
    :hook (python-base-mode . flymake-ruff-load))

(use-package poetry :after python :disabled
    :functions (poetry-tracking-mode)
    ;:ensure-system-package ((poetry . "pip install poetry"))
    :hook (python-base-mode . poetry-tracking-mode)
    )

(use-package lsp-pyright :after (python)
    :custom (lsp-pyright-langserver-command "basedpyright")
    ;:hook (python-base-mode .
    ;          (lambda ()
    ;              (require 'lsp-pyright)
    ;              (require 'lsp-ruff)
    ;              (lsp-deferred)))
    )

(use-package jinja2-mode)

(use-package jupyter :disabled)


(provide '+python)
;;; +python.el ends here
