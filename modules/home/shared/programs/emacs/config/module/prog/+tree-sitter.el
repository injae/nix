;;; +tree-sitter.el --- Summery -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

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
        '((bash             "https://github.com/tree-sitter/tree-sitter-bash")
          (cmake            "https://github.com/uyha/tree-sitter-cmake")
          (css              "https://github.com/tree-sitter/tree-sitter-css")
          (elisp            "https://github.com/Wilfred/tree-sitter-elisp")
          (go               "https://github.com/tree-sitter/tree-sitter-go")
          (html             "https://github.com/tree-sitter/tree-sitter-html")
          (javascript       "https://github.com/tree-sitter/tree-sitter-javascript" "master" "src")
          (json             "https://github.com/tree-sitter/tree-sitter-json")
          (make             "https://github.com/alemuller/tree-sitter-make")
          (markdown         "https://github.com/tree-sitter-grammars/tree-sitter-markdown" "split_parser" "tree-sitter-markdown/src")
          (markdown-inline  "https://github.com/tree-sitter-grammars/tree-sitter-markdown" "split_parser" "tree-sitter-markdown-inline/src")
          (nix              "https://github.com/nix-community/tree-sitter-nix")
          (python           "https://github.com/tree-sitter/tree-sitter-python")
          (toml             "https://github.com/tree-sitter/tree-sitter-toml")
          (tsx              "https://github.com/tree-sitter/tree-sitter-typescript" "master" "tsx/src")
          (typescript       "https://github.com/tree-sitter/tree-sitter-typescript" "master" "typescript/src")
          (vue              "https://github.com/ikatyang/tree-sitter-vue")
          (yaml             "https://github.com/ikatyang/tree-sitter-yaml")))
    (setq treesit-font-lock-level 4)
)

(use-package combobulate :ensure (:type git :host github :repo "mickeynp/combobulate")
    :custom (combobulate-key-prefix "C-c C-o")
    :hook ((prog-mode . combobulate-mode))
    )

(provide '+tree-sitter)
;;; +tree-sitter.el ends here
