;;; +git.el --- Summery -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:


(use-package emacs-lisp :no-require t :after general :ensure nil
    :general (leader "le" '(eval-print-last-sexp :wk "Elisp Evaluate"))
    :hook (emacs-lisp-mode . (lambda () (setq format-all-formatters '(("Emacs Lisp")))))
    )

(use-package scratch-comment
    :general (:keymaps 'lisp-interaction-mode-map "C-j" 'scratch-comment-eval-sexp)
    )

(use-package slime :disabled
    :commands slime
    :config
    (setq inferior-lisp-program (or (executable-find "sbcl")
                                    (executable-find "/usr/bin/sbcl")
                                    (executable-find "/usr/sbin/sbcl" )))
    (require 'slime-autoloads)
    (slime-setup '(slime-fancy))
    )
(use-package elisp-slime-nav :diminish elisp-slime-nav-mode
    :hook ((emacs-lisp-mode ielm-mode) . elisp-slime-nav-mode)
    )

(use-package prettify-symbols :no-require t :ensure nil
    :hook ((emacs-lisp-mode lisp-mode org-mode) . prettify-symbols-mode)
    )

(provide '+lisp)
;;; +lisp.el ends here
