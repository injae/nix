;;; +json.el --- Summery -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(use-package json-mode
    :mode  (("\\.json\\'" . json-ts-mode))
    :preface
    (defun json-pretty (start end)
        (interactive "*r")
        (replace-string "\\\"" "\"" nil start end)
        (json-pretty-print-buffer)
    )

    (defun temp-json-pretty-buffer ()
        "json pretty print buffer"
        (interactive)
        (temp-buffer)
        (require 'jsonian-mode)
        (jsonian-mode)
        (yank-pop)
        (json-pretty (region-beginning) (region-end))
        )
    :custom
    (json-ts-mode-indent-offset 2)
)

(use-package jsonian :ensure (:type git :host github :repo "iwahbe/jsonian")
    :after so-long
    :custom (jsonian-no-so-long-mode)
    )

(use-package json-reformat
	:commands json-reformat-region)

(use-package jq-mode
	:commands jq-interactively)

(use-package jq-ts-mode :after jq-mode
	:config
	(add-to-list
		'treesit-language-source-alist
		'(jq "https://github.com/nverno/tree-sitter-jq" nil nil nil))
	)

(provide '+json)
;;; +json.el ends here
