;;; +flyspell.el --- Summery -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

;; Superseded by jinx below.  Kept until the personal dictionary carried over
;; to `config/enchant' proves itself, then this and the two packages after it
;; can go, along with `config/.personal-dict'.
(use-package flyspell :ensure nil :disabled
    :general (leader "sk" '((lambda () (interactive) (ispell-change-dictionary "ko_KR") (flyspell-buffer)) :wk "Spell Dictionary Korean")
                     "se" '((lambda () (interactive) (ispell-change-dictionary "en_US") (flyspell-buffer)) :wk "Spell Dictionary English"))
    :hook ((prog-mode . flyspell-mode)
           (text-mode . flyspell-mode))
    :custom (ispell-dictionary   "en_US")
    :config
        ;; Make sure new aspell is installed
        (when (executable-find "aspell")
            (setq ispell-program-name "aspell")
            (setq ispell-list-command "--list"))
        (setq-default ispell-extra-args '("--sug-mode=ultra" "--lang=en_US" "--camel-case"))

        (setq ispell-personal-dictionary (f-join user-mutable-emacs-directory "config/.personal-dict"))
        ;; 스펠체크 넘어가는 부분 설정
        ;(add-to-list 'ispell-skip-region-alist '(":\\(PROPERTIES\\|LOGBOOK\\):" . ":END:"))
        ;(add-to-list 'ispell-skip-region-alist '("#\\+BEGIN_SRC" . "#\\+END_SRC"))
        ;(add-to-list 'ispell-skip-region-alist '("#\\+BEGIN_EXAMPLE" . "#\\+END_EXAMPLE"))
)

(use-package flyspell-correct :after flyspell :disabled
    :general (leader "sf"  #'flyspell-correct-wrapper)
    :config
    (define-key flyspell-mode-map (kbd "C-;") #'flyspell-correct-wrapper)
    )

(use-package consult-flyspell :after (flyspell-correct consult) :disabled
    :custom
          (consult-flyspell-select-function      nil
           consult-flyspell-set-point-after-word t
           consult-flyspell-always-check-buffer  nil)
          (consult-flyspell-correct-function (lambda () (flyspell-correct-at-point) (consult-flyspell))))

;; Korean comes from hunspell-dict-ko, added in programs/aspell:
;; https://github.com/spellcheck-ko/hunspell-dict-ko
(use-package jinx
    :preface
    ;; Words accepted through `jinx-correct' go to the Enchant backend's own
    ;; word list, so point Enchant inside this repository to keep the personal
    ;; dictionary tracked the way `ispell-personal-dictionary' was.
    (setenv "ENCHANT_CONFIG_DIR" (f-join user-mutable-emacs-directory "config/enchant"))
    :hook (emacs-startup . global-jinx-mode)
    :custom (jinx-languages "en_US ko_KR")
    :general (leader "sf" '(jinx-correct :wk "Spell Correct")
                     "sk" '((lambda () (interactive) (jinx-languages "ko_KR")) :wk "Spell Dictionary Korean")
                     "se" '((lambda () (interactive) (jinx-languages "en_US")) :wk "Spell Dictionary English"))
    :bind (:map jinx-mode-map ("C-;" . jinx-correct)))

(provide '+flyspell)
;;; +flyspell.el ends here
