;;; +json.el --- Summery -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:


(use-package json-mode
    :mode  (("\\.json\\'"       . json-mode)
            ("/Pipfile.lock\\'" . json-mode))
)

(use-package jsonian :ensure (:type git :host github :repo "iwahbe/jsonian")
    :after so-long
    :custom (jsonian-no-so-long-mode)
    :config
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
