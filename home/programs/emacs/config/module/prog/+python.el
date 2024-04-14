;;; +python.el --- Summery -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(use-package python-mode :after exec-path-from-shell
    :mode (("\\.py\\'" . python-ts-mode)
           ("\\.wsgi$" . python-ts-mode))
    :preface
    (defun python-formatting-hook ()
        (setq format-all-formatters '(("Python" ruff))))
    :hook (python-base-mode . python-formatting-hook)
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

(use-package pyenv :after exec-path-from-shell :disabled
    :preface
    (defun projectile-pyenv-mode-set ()
    "Set pyenv version matching project name."
        (let ((project (projectile-project-name)))
            (if (member project (pyenv-mode-versions))
                (pyenv-mode-set project)
            (pyenv-mode-unset))))
    :config
    (add-hook 'projectile-after-switch-project-hook 'projectile-pyenv-mode-set)
    )

(use-package python-pytest)

(use-package pet :after python :disabled
    :config
    (add-hook 'python-base-mode-hook 'pet-mode -10)
    (add-hook 'python-base-mode-hook 'pet-flycheck-setup)
    )

(use-package flymake-ruff :after (python eglot)
    :hook (python-base-mode . flymake-ruff-load))

(use-package poetry :after python :disabled
    :functions (poetry-tracking-mode)
    ;:ensure-system-package ((poetry . "pip install poetry"))
    :hook (python-base-mode . poetry-tracking-mode)
    )

(use-package lsp-pyright :after (python)
    :hook (python-base-mode .
              (lambda ()
                  (require 'lsp-pyright)
                  (require 'lsp-ruff-lsp)
                  (lsp-deferred)))
    )

(use-package jinja2-mode)

(use-package jupyter :disabled)


(provide '+python)
;;; +python.el ends here
