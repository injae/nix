;;; +ui.el --- Summery -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(use-package all-the-icons)

(use-package all-the-icons-nerd-fonts :ensure (:host github :repo "mohkale/all-the-icons-nerd-fonts")
    :after all-the-icons
    :config (all-the-icons-nerd-fonts-prefer)
    )

(use-package all-the-icons-ibuffer
:after all-the-icons
:hook (ibuffer-mode . all-the-icons-ibuffer-mode)
)

(use-package all-the-icons-completion
:hook (emacs-startup . all-the-icons-completion-mode)
)

(use-package beacon
    :hook (emacs-startup . beacon-mode))

(use-package diff-hl
    :hook
    ((magit-pre-refresh  . diff-hl-magit-pre-refresh)
     (magit-post-refresh . diff-hl-magit-post-refresh)
     (emacs-startup      . global-diff-hl-mode))
    :init
    (setq-default display-line-numbers-width 3)
    (global-display-line-numbers-mode t)
    (global-hl-line-mode t)
)

(use-package highlight-numbers
:hook (prog-mode . highlight-numbers-mode)
)

;; 현재 발견된 doom-theme 버그
;; emacs29 이상에서 아래 메세지 출력
;; Warning: setting attribute ‘:background’ of face ‘font-lock-comment-face’: nil value is invalid, use ‘unspecified’ instead.
(use-package doom-themes
:init (setq custom-safe-themes t)
:config (load-theme   'doom-vibrant t)
    (doom-themes-visual-bell-config)
    (doom-themes-neotree-config)
    (doom-themes-org-config)
    (doom-themes-treemacs-config)
)

(use-package nerd-icons
    :ensure (:type git :host github :repo "rainstormstudio/nerd-icons.el"
             :files (:defaults "data"))
)


(use-package doom-modeline :after nerd-icons
  :custom
    (doom-modeline-buffer-file-name-style 'truncate-with-project)
    (doom-modeline-height 30)
    (doom-modeline-icon t) ; current version has error
    (doom-modeline-persp-name t)
    (doom-modeline-major-mode-icon t)
    (doom-modeline-enable-word-count t)
    (doom-modeline-lsp t)
    
    (doom-modeline-current-window t)
    (doom-modeline-env-version t)
    (doom-modeline-env-enable-python t)
    (doom-modeline-env-enable-ruby t)
    (doom-modeline-env-ruby-executable "ruby")
    (doom-modeline-env-enable-elixir t)
    (doom-modeline-env-elixir-executable "iex")
    (doom-modeline-env-enable-go t)
    (doom-modeline-env-go-executable "go")
    (doom-modeline-env-enable-perl t)
    (doom-modeline-env-perl-executable "perl")
    (doom-modeline-env-rust-executable "rustc")
    (doom-modeline-github t)
    (doom-modeline--flycheck-icon t)
    (doom-modeline-current-window t)
    (doom-modeline-major-mode-color-icon t)
    ;; (doom-modeline-iconer-state-icon t)
    ;; (doom-modeline--battery-status t)
  :init
    (setq find-file-visit-truename t)
    (setq inhibit-compacting-font-caches t)
  :config
    (doom-modeline-mode 1)
)

(use-package rainbow-mode
  :hook   (prog-mode text-mode)
  :config (rainbow-mode)
)

(use-package rainbow-delimiters
  :hook ((prog-mode . rainbow-delimiters-mode)
         (text-mode . rainbow-delimiters-mode))
)

(use-package modern-fringes :disabled
  :config
    (modern-fringes-mode)
    (modern-fringes-invert-arrows)
)

; 자동으로 Dark mode Light mode 변환
(use-package mac-dark-mode :no-require t :disabled
  :if *is-mac*
  :preface
  (defun set-system-dark-mode ()
      (interactive)
      (if (string=
            (shell-command-to-string "printf %s \"$( osascript -e \'tell application \"System Events\" to tell appearance preferences to return dark mode\' )\"") "true")
          (load-theme 'doom-one t) ; dark-mode
          (load-theme 'doom-city-lights t)) ; light-mode
  )
  :config (run-with-idle-timer 60 t (lambda () (set-system-dark-mode)))  ; 1분마다, repeat
)

(use-package hide-mode-line :after neotree
  :hook  (neotree-mode . hide-mode-line-mode)
)

(use-package indent-bars :ensure (:host github :repo "jdtsmith/indent-bars")
  :hook ((prog-mode    . indent-bars-mode)
         (yaml-mode    . indent-bars-mode)
         (toml-mode    . indent-bars-mode)
         (json-mode    . indent-bars-mode)
         (jsonian-mode . indent-bars-mode))
  :custom
  (indent-bars-no-descend-lists 'skip)
  (indent-bars-treesit-support t)
  (indent-bars-treesit-ignore-blank-lines-types '("module"))
  (indent-bars-treesit-scope '((python function_definition class_definition for_statement
	  if_statement with_statement while_statement)))
  (indent-bars-no-descend-string t)

  :config
  (setq
    indent-bars-width-frac 0.3
    indent-bars-pad-frac 0.3
    indent-bars-pattern "."
    indent-bars-zigzag nil
    indent-bars-color-by-depth '(:regexp "outline-\\([0-9]+\\)" :blend 1) ; blend=1: blend with BG only
    indent-bars-highlight-current-depth '(:blend 0.5) ; pump up the BG blend on current
    indent-bars-display-on-blank-lines nil)
)


(use-package nyan-mode :disabled
  :custom (nyan-wavy-trail t)
  :config (nyan-mode)
          (nyan-start-animation)
)

(use-package neotree :after (projectile all-the-icons)
:commands (neotree-toggle)
:general (leader "n" #'neotree-toggle)
:init
    (setq projectile-switch-project-action 'neotree-projectile-action)
    (setq-default neo-smart-open t)
:hook (neotree-mode . (lambda () (display-line-numbers-mode -1) ))
:config
    (setq-default neo-window-width 30)
    (setq-default neo-dont-be-alone t)
    (setq neo-force-change-root t)
    (setq neo-theme (if (display-graphic-p) 'icons 'arrow))
    (setq neo-show-hidden-files t)
)

(use-package all-the-icons-dired
:after all-the-icons
:init  (add-hook 'dired-mode-hook 'all-the-icons-dired-mode))

(defun copy-file-name-to-clipboard ()
    "Copy the current buffer file name to the clipboard."
    (interactive)
    (let ((filename (if (equal major-mode 'dired-mode) default-directory (buffer-file-name))))
        (when filename
        (kill-new filename)
            (message "Copied buffer file name '%s' to the clipboard." filename)))
)

(provide '+ui)
;;; +ui.el ends here
