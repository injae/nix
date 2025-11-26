;;; +tree-sitter.el --- Summery -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(use-package tree-sitter
  :hook ((emacs-startup . global-tree-sitter-mode)
         (tree-sitter-after-on . tree-sitter-hl-mode))
)

;; 
(use-package tree-sitter-langs :after tree-sitter)
(use-package tree-sitter-indent :after tree-sitter :disabled
  :hook (tree-sitter-after-on . tree-sitter-indent-mode)
  )
;(use-package tsi :ensure (:type git :host github :repo "orzechowskid/tsi.el") :after tree-sitter :disabled)

(use-package evil-textobj-tree-sitter :after (evil tree-sitter)
  :config
  ;; bind `function.outer`(entire function block) to `f` for use in things like `vaf`, `yaf`
  (define-key evil-outer-text-objects-map "f" (evil-textobj-tree-sitter-get-textobj "function.outer"))
  ;; bind `function.inner`(function block without name and args) to `f` for use in things like `vif`, `yif`
  (define-key evil-inner-text-objects-map "f" (evil-textobj-tree-sitter-get-textobj "function.inner"))

  ;; You can also bind multiple items and we will match the first one we can find
  (define-key evil-outer-text-objects-map "a" (evil-textobj-tree-sitter-get-textobj ("conditional.outer" "loop.outer")))
  )

(use-package treesit-auto :disabled
    ;:custom (treesit-auto-install 'prompt)
    :config
    ;; (treesit-auto-add-to-auto-mode-alist 'all)
    (global-treesit-auto-mode)
    )

(use-package treesit :ensure nil
    :if (treesit-available-p)
    :preface
    ;; Function to install missing grammars
    (defun my/install-treesit-grammars ()
        "Install missing Tree-sitter grammars."
        (interactive)
        (dolist (grammar treesit-language-source-alist)
            (let ((lang (car grammar)))
            (unless (treesit-language-available-p lang)
                (treesit-install-language-grammar lang)))))
    :config
    (setq treesit-language-source-alist
        '((bash "https://github.com/tree-sitter/tree-sitter-bash")
          (cmake "https://github.com/uyha/tree-sitter-cmake")
          (css "https://github.com/tree-sitter/tree-sitter-css")
          (elisp "https://github.com/Wilfred/tree-sitter-elisp")
          (go "https://github.com/tree-sitter/tree-sitter-go")
          (html "https://github.com/tree-sitter/tree-sitter-html")
          (javascript "https://github.com/tree-sitter/tree-sitter-javascript" "master" "src")
          (json "https://github.com/tree-sitter/tree-sitter-json")
          (make "https://github.com/alemuller/tree-sitter-make")
          (markdown "https://github.com/ikatyang/tree-sitter-markdown")
          (python "https://github.com/tree-sitter/tree-sitter-python")
          (toml "https://github.com/tree-sitter/tree-sitter-toml")
          (tsx "https://github.com/tree-sitter/tree-sitter-typescript" "master" "tsx/src")
          (typescript "https://github.com/tree-sitter/tree-sitter-typescript" "master" "typescript/src")
          (nix "https://github.com/nix-community/tree-sitter-nix")
          (yaml "https://github.com/ikatyang/tree-sitter-yaml")))
    (setq treesit-font-lock-level 4)
)

(use-package combobulate :ensure (:type git :host github :repo "mickeynp/combobulate")
    :custom (combobulate-key-prefix "C-c C-o")
    :hook ((prog-mode . combobulate-mode))
    )


(use-package treesit-langs :disabled
    :ensure (treesit-langs :repo "kiennq/treesit-langs"
                           :host github
                           :files (:defaults "treesit-*.el" "queries"))
    :hook (prog-mode .
              (lambda () (ignore-errors (treesit-hl-toggle))))
    :custom
        (treesit-langs-git-dir nil)
        (treesit-langs-grammar-dir (expand-file-name "tree-sitter" user-emacs-directory))
    :config (add-to-list 'treesit-extra-load-path treesit-langs-grammar-dir)
)

(provide '+tree-sitter)
;;; +tree-sitter.el ends here
