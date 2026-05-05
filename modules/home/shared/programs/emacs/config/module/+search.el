;;; +search.el --- Summery -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(use-package google-this
:commands google-this
:general (leader "fw" '(google-this-region :wk "Search Word"))
:config  (google-this-mode 1)
)

;; google translation # need to migration
(use-package google-translate
:general (leader "ft" 'google-translate-smooth-ui)
:config
  (setq google-translate-default-target-language "ko")
  (setq google-translate-translation-directions-alist
      '(("en" . "ko") ("ko" . "en") ("ja" . "ko") ("ko" . "ja") ("zh-CN" . "ko") ("ko" . "zh-CN")))
)

(use-package avy
:general (leader "jl" '(avy-goto-line :wk "Jump to line")
                 "jw" '(avy-goto-char :wk "Jump to word"))
)

(provide '+search)
;;; +search.el ends here
