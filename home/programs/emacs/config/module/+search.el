;;; +search.el --- Summery -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(use-package google-this
:commands google-this
:general (leader "fw" '(google-this :wk "Search Word"))
:config  (google-this-mode 1)
)

;; google translation # need to migration
(use-package go-translate
:general (leader "ft" 'gt-do-translate)
:config
    (setq gt-translate-list '(("en" "ko") ("jp" "ko")))
    (setq gt-default-translator
        (gt-translator
            :picker (gts-prompt-picker)
            :engines (list (gts-bing-engine) (gts-google-engine))
            :render (gts-posframe-pop-render)
            ))
)

(use-package avy
:general (leader "jl" '(avy-goto-line :wk "Jump to line")
                 "jw" '(avy-goto-char :wk "Jump to word"))
)


(provide '+search)
;;; +search.el ends here
