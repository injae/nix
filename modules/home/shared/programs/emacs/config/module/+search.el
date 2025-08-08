;;; +search.el --- Summery -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(use-package google-this
:commands google-this
:general (leader "fw" '(google-this-symbol :wk "Search Word"))
:config  (google-this-mode 1)
)

;; google translation # need to migration
(use-package google-translate
:general (leader "ft" 'gt-do-translate)
:config
    (setq gt-langs '(en ko jp))
    (setq gt-default-translator
        (gt-translator
            :taker (gt-taker :text t)
            :engines (list (gt-google-engine))
            :render (gt-posframe-pop-render)
            ))
)

(use-package avy
:general (leader "jl" '(avy-goto-line :wk "Jump to line")
                 "jw" '(avy-goto-char :wk "Jump to word"))
)


(provide '+search)
;;; +search.el ends here
