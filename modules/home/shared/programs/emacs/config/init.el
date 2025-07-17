;;; init.el --- Emacs Configuration -*- lexical-binding: t -*-
;;; Commentary:
;; This config start here
;;; Code:

;; Waring: Unable to determine elpaca-core-date
;;get number (string-to-number (nth 1 (elpaca-process-call "git" "log" "-n" "1" "--format=%cd" "--date=format:%Y%m%d")))
;; https://github.com/progfolio/elpaca/issues/222

;(defun my/nixos/get-emacs-build-date ()
;  "Return NixOS Emacs build date."
; (string-match "--prefix.*emacs.*\\([[:digit:]]\\{8\\}\\)" system-configuration-options)
;  (string-to-number (match-string 1 system-configuration-options)))

;; https://github.com/progfolio/elpaca/issues/222
;;(when (not (boundp 'elpaca-core-date)) (setq elpaca-core-date (list (my/nixos/get-emacs-build-date))))

(defun my/nixos-p ()
  "Return t if operating system is NixOS, nil otherwise."
  (string-match-p "NixOS" (shell-command-to-string "uname -v")))

(defun my/nixos/get-emacs-build-date ()
  "Return NixOS Emacs build date."
  (string-match "--prefix.*emacs.*\\([[:digit:]]\\{8\\}\\)" system-configuration-options)
  (string-to-number (match-string 1 system-configuration-options)))

;; Run this before the elpaca.el is loaded. Before the installer in your init.el is a good spot.
(when (my/nixos-p) (setq elpaca-core-date (list (my/nixos/get-emacs-build-date))))

(defvar elpaca-installer-version 0.11)
(defvar elpaca-directory (expand-file-name "elpaca/" user-emacs-directory))
(defvar elpaca-builds-directory (expand-file-name "builds/" elpaca-directory))
(defvar elpaca-repos-directory (expand-file-name "repos/" elpaca-directory))
(defvar elpaca-order '(elpaca :repo "https://github.com/progfolio/elpaca.git"
                              :ref nil :depth 1 :inherit ignore
                              :files (:defaults "elpaca-test.el" (:exclude "extensions"))
                              :build (:not elpaca--activate-package)))
(let* ((repo  (expand-file-name "elpaca/" elpaca-repos-directory))
       (build (expand-file-name "elpaca/" elpaca-builds-directory))
       (order (cdr elpaca-order))
       (default-directory repo))
  (add-to-list 'load-path (if (file-exists-p build) build repo))
  (unless (file-exists-p repo)
    (make-directory repo t)
    (when (<= emacs-major-version 28) (require 'subr-x))
    (condition-case-unless-debug err
        (if-let* ((buffer (pop-to-buffer-same-window "*elpaca-bootstrap*"))
                  ((zerop (apply #'call-process `("git" nil ,buffer t "clone"
                                                  ,@(when-let* ((depth (plist-get order :depth)))
                                                      (list (format "--depth=%d" depth) "--no-single-branch"))
                                                  ,(plist-get order :repo) ,repo))))
                  ((zerop (call-process "git" nil buffer t "checkout"
                                        (or (plist-get order :ref) "--"))))
                  (emacs (concat invocation-directory invocation-name))
                  ((zerop (call-process emacs nil buffer nil "-Q" "-L" "." "--batch"
                                        "--eval" "(byte-recompile-directory \".\" 0 'force)")))
                  ((require 'elpaca))
                  ((elpaca-generate-autoloads "elpaca" repo)))
            (progn (message "%s" (buffer-string)) (kill-buffer buffer))
          (error "%s" (with-current-buffer buffer (buffer-string))))
      ((error) (warn "%s" err) (delete-directory repo 'recursive))))
  (unless (require 'elpaca-autoloads nil t)
    (require 'elpaca)
    (elpaca-generate-autoloads "elpaca" repo)
    (let ((load-source-file-function nil)) (load "./elpaca-autoloads"))))
(add-hook 'after-init-hook #'elpaca-process-queues)
(elpaca `(,@elpaca-order))

(elpaca elpaca-use-package
    (elpaca-use-package-mode)
    (setq elpaca-use-package-by-default t)
    )

(elpaca-wait)

(use-package exec-path-from-shell
    :custom (
                (exec-path-from-shell-variables '("PATH"
                                                  "MANPATH"
                                                  "TMPDIR"
                                                  "KUBECONFIG"
                                                  "LSP_USE_PLISTS"
                                                  "GOPRIVATE"
                                                  "RUST_BACKTRACE"
                                                  "MallocNanoZone"))
                (exec-path-from-shell-arguments '("-l"))
                (exec-path-from-shell-check-startup-files nil)
                (exec-path-from-shell-debug nil)
                )
    :config (exec-path-from-shell-initialize)
    )

(elpaca-wait)

(use-package direnv :disabled
    :after exec-path-from-shell
    :config (direnv-mode)
    )

(use-package agenix :after exec-path-from-shell)

(use-package envrc
    :after exec-path-from-shell
    :hook (agenix-pre-mode . envrc-mode)
    :init (envrc-global-mode)
    )

(use-package no-littering
    :config (require 'recentf)
    (add-to-list 'recentf-exclude no-littering-var-directory)
    (add-to-list 'recentf-exclude no-littering-etc-directory)
    (setq auto-save-file-name-transforms `((".*" ,(no-littering-expand-var-file-name "auto-save/") t)))
    )

;; custom lisp library
(add-to-list 'load-path (expand-file-name "~/.emacs.d/lisp/"))

(setq-default custom-file "~/.emacs.d/custom-variable.el")
(when (file-exists-p custom-file) (load-file custom-file))

(use-package +lisp-util :ensure nil :load-path "~/.emacs.d/module/")

(elpaca-wait)

(setq user-full-name "injae lee")
(setq user-mail-address "8687lee@gmail.com")

(elpaca-wait)

(use-package module-util :ensure nil :after (dash f s)
    :init
    (setq-default user-nix-directory (expand-file-name "~/nix"))
    (setq-default user-mutable-emacs-directory (f-join user-nix-directory "modules/home/shared/programs/emacs"))
    (setq-default user-emacs-module-directory (f-join user-emacs-directory "module"))
    (setq-default user-emacs-prog-module-directory (f-join user-emacs-module-directory "prog"))
    :config
    ;; Emacs 기본설정
    (load-modules-with-list user-emacs-module-directory
        '( ;; emacs modules
             emacs font evil
             git grep-util extension
             project-manage completion
             window   buffer  ui
             org terminal edit
             flycheck search
             multi-mode util
             run-command
             third-party
             ai
             ))
    ;; programming 설정
    (load-modules-with-list user-emacs-prog-module-directory
        '( ;; programming modules
             tree-sitter lsp debug snippet
             prog-search doc ssh
             coverage copilot tools
             ;;; language support
             just cpp lisp csharp
             rust python gleam
             flutter web ruby
             jvm  go  nix lua
             config-file docker
             formatting bazel
             markdown json terraform
             ))
    )

;;; init.el ends here
