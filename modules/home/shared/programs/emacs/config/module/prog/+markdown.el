;;; +markdown.el --- Summery -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(use-package markdown-ts-mode
    :mode ("\\.md\\'"       . markdown-ts-mode)
    :config
    (add-to-list 'treesit-language-source-alist
        '(markdown "https://github.com/tree-sitter-grammars/tree-sitter-markdown" "split_parser" "tree-sitter-markdown/src"))
    (add-to-list 'treesit-language-source-alist
        '(markdown-inline "https://github.com/tree-sitter-grammars/tree-sitter-markdown" "split_parser" "tree-sitter-markdown-inline/src"))
    )

(provide '+markdown)
;;; +markdown.el ends here
