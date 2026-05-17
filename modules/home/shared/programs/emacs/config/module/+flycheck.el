;;; +flycheck.el --- Summery -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

;(setq flymake-mode nil)

(use-package flycheck :after (exec-path-from-shell projectile) :disabled
    :custom (flycheck-clang-language-standard "c++17")
    :hook (emacs-startup . global-flycheck-mode)
    :config
    (remove-hook 'flymake-diagnostic-functions 'flymake-proc-legacy-flymake)
    ;; flycheck lsp and something
    (defvar-local my/flycheck-local-cache nil)
    (defun my/flycheck-checker-get (fn checker property)
        (or (alist-get property (alist-get checker my/flycheck-local-cache))
            (funcall fn checker property)))
    (advice-add 'flycheck-checker-get :around 'my/flycheck-checker-get)
    (add-hook 'lsp-managed-mode-hook
            (lambda ()
                (when (derived-mode-p 'python-base-mode)
                    (setq my/flycheck-local-cache
                        '((lsp . ((next-checkers . (python-mypy))))
                             )))))
)

(use-package flycheck-package :after flycheck
    :config (flycheck-package-setup))

(provide '+flycheck)
;;; +flycheck.el ends here
