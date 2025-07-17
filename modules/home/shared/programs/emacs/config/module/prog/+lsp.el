;;; +lsp.el --- Summery -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(use-package lsp-mode :after (exec-path-from-shell projectile)
:commands (lsp lsp-deferred)
:custom (lsp-inhibit-message t)
        (lsp-message-project-root-warning t)
        (lsp-enable-file-watchers nil)
        (lsp-file-watch-threshold 1000)
        (lsp-enable-completion-at-point t)
        (lsp-prefer-flymake nil)
        (lsp-auto-guess-root t)
        (lsp-response-timeout 25)
        (lsp-eldoc-render-all nil)
        (lsp-enable-indentation nil) ; use apheleia
        (lsp-enable-on-type-formatting nil) ; use apheleia
        (lsp-enable-dap-auto-configure t)
        (lsp-completion-show-kind t)
        (lsp-lens-enable t)
        (lsp-enable-snippet t)
        (lsp-enable-links t)
        (lsp-idle-delay 0.500)
        (lsp-log-io t)
        (lsp-rust-analyzer-server-display-inlay-hints nil)
        (lsp-headerline-breadcrumb-enable-diagnostics nil)
        (lsp-completion-provider :none) ; with corfu
        (lsp-diagnostics-provider :flycheck)
        (lsp-enable-suggest-server-download nil)
        (lsp-javascript-format-enable nil)
        (lsp-typescript-format-enable nil)
        (lsp-disabled-clients '(tfls))
        ;(lsp-rust-analyzer-cargo-watch-command "clipy")
:init
    (defun my/lsp-mode-setup-completion ()
        (setf (alist-get 'styles (alist-get 'lsp-capf completion-category-defaults))
            '(orderless)))


:hook ((lsp-completion-mode . my/lsp-mode-setup-completion)
       ;(before-save         . lsp-format-buffer)
       (lsp-mode            . lsp-enable-which-key-integration)
       (rust-mode           . lsp-deferred)
       (go-ts-mode          . lsp-deferred)
       (go-mode             . lsp-deferred))

:config
    ;(lsp-mode)
    ;;corfu + lsp pause bugfix
    ;; (advice-add #'lsp-completion-at-point :around #'cape-wrap-noninterruptible)
    (dolist (dir '("[/\\\\]\\.ccls-cache\\'"
                    "[/\\\\]\\.mypy_cache\\'"
                    "[/\\\\]\\.pytest_cache\\'"
                    "[/\\\\]\\.cache\\'"
                    "[/\\\\]\\.clwb\\'"
                    "[/\\\\]__pycache__\\'"
                    "[/\\\\]bazel-bin\\'"
                    "[/\\\\]bazel-code\\'"
                    "[/\\\\]bazel-genfiles\\'"
                    "[/\\\\]bazel-out\\'"
                    "[/\\\\]bazel-testlogs\\'"
                    "[/\\\\]third_party\\'"
                    "[/\\\\]third-party\\'"
                    "[/\\\\]buildtools\\'"
                    "[/\\\\]out\\'"
                    "[/\\\\]build\\'"
                    ))
        (push dir lsp-file-watch-ignored-directories))

    (setq lsp-pyright-multi-root nil)
    (setq lsp-go-use-gofumpt t)
    (setq lsp-gopls-hover-kind "NoDocumentation")
    (lsp-register-custom-settings
        '(("gopls.staticcheck" t t)
          ("gopls.allExperiments" t t)
          ;;("gopls.usePlaceholders" t t)
          ("rust-analyzer.cargo.runBuildScript" t t)

          ;;("pylsp.plugins.black.enabled" t t)
          ;;("pylsp.plugins.ruff.enabled" t t)
          ;;("pylsp.plugins.rope_autoimport.enabled" t t)
          ))

    (setq lsp-go-analyses
        '((unusedparams . t)
          (unreachable . t)
          (unusedwrite . t)
          (useany . t)))
    (setq lsp-go-gopls-placeholders nil)
    ;(defvar-local lsp-format-on-save t "Format `lsp-mode'-managed buffer before save.")
    ;(defun lsp-format-on-save-not-apheleia ()
    ;"Format on save using LSP server, not `apheleia'."
    ;    (progn
    ;        (add-hook 'before-save-hook #'lsp-format-buffer nil 'local)
    ;        (setq-local apheleia-mode nil)))
    ;(add-hook 'lsp-configure-hook #'lsp-format-on-save-not-apheleia)
)

(use-package lsp-ui :after lsp-mode
:commands lsp-ui-mode
:general (leader ;"ld"  #'lsp-ui-doc-focus-frame
                 "lpr" #'lsp-ui-peek-find-references
                 "lpd" #'lsp-ui-peek-find-definitions
                 "lpi" #'lsp-ui-peek-find-implementation)
         (:keymaps 'lsp-ui-peek-mode-map
                 "k"   #'lsp-ui-peek--select-prev
                 "j"   #'lsp-ui-peek--select-next)

:custom (scroll-margin 0)
        (lsp-headerline-breadcrumb-icons-enable t)
        (lsp-lens-enable nil)
        (lsp-ui-peek-enable t)
        (lsp-ui-flycheck-enable t)
        (lsp-ui-doc-enable t)
        (lsp-ui-doc-show-with-cursor t)
        (lsp-ui-sideline-enable t)
        (lsp-ui-sideline-show-hover nil)
        (lsp-ui-sideline-actions-icon nil)
        (lsp-ui-sideline-show-code-actions t)
        ;(lsp-ui-sideline-show-diagnostics t)
)

(use-package lsp-booster :ensure nil :no-require t :after lsp-mode
    :config
    (defun lsp-booster--advice-json-parse (old-fn &rest args)
        "Try to parse bytecode instead of json."
        (or
            (when (equal (following-char) ?#)
                (let ((bytecode (read (current-buffer))))
                (when (byte-code-function-p bytecode)
                    (funcall bytecode))))
            (apply old-fn args)))
                (advice-add (if (progn (require 'json)
                                    (fboundp 'json-parse-buffer))
                                'json-parse-buffer
                            'json-read)
                            :around #'lsp-booster--advice-json-parse)

    (defun lsp-booster--advice-final-command (old-fn cmd &optional test?)
    "Prepend emacs-lsp-booster command to lsp CMD."
        (let ((orig-result (funcall old-fn cmd test?)))
            (if (and (not test?)                            ;; for check lsp-server-present?
                    (not (file-remote-p default-directory)) ;; see lsp-resolve-final-command, it would add extra shell wrapper
                    lsp-use-plists
                    (not (functionp 'json-rpc-connection))  ;; native json-rpc
                    (executable-find "emacs-lsp-booster"))
                (progn
                (message "Using emacs-lsp-booster for %s!" orig-result)
                (cons "emacs-lsp-booster" orig-result))
            orig-result)))
    (advice-add 'lsp-resolve-final-command :around #'lsp-booster--advice-final-command)
    )


(use-package treemacs :disabled :config (setq treemacs-resize-icons 22))
(use-package treemacs-evil :after (treemacs evil))
(use-package treemacs-projectile :after (treemacs projectile))

(use-package lsp-treemacs :disabled
:after (lsp-mode doom-modeline)
:config ;(setq lsp-metals-treeview-enable t)
        ;(setq lsp-metals-treeview-show-when-views-received t)
        (lsp-treemacs-sync-mode 1)
)

(use-package dap-mode :disabled
:after lsp-mode
:commands (dap-debug)
:general (leader "dd" 'dap-debug)
;:custom (dap-lldb-debug-program '("/Users/nieel/.vscode/extensions/lanza.lldb-vscode-0.2.2/bin/darwin/bin/lldb-vscode"))
:config
    (setq dap-auto-configure-features '(sessions locals controls tooltip))
    (add-hook 'dap-stopped-hook (lambda (arg) (call-interactively #'dap-hydra)))
    (dap-mode)
)

(use-package dap-ui-setting :no-require t :ensure nil
:after dap-mode
:preface
  (defun my/window-visible (b-name)
      "Return whether B-NAME is visible."
      (-> (-compose 'buffer-name 'window-buffer)
          (-map (window-list))
          (-contains? b-name)))

  (defun my/show-debug-windows (session)
      "Show debug windows."
      (let ((lsp--cur-workspace (dap--debug-session-workspace session)))
          (save-excursion
          ;; display locals
          (unless (my/window-visible dap-ui--locals-buffer)
              (dap-ui-locals))
          ;; display sessions
          (unless (my/window-visible dap-ui--sessions-buffer)
              (dap-ui-sessions)))))

  (defun my/hide-debug-windows (session)
      "Hide debug windows when all debug sessions are dead."
      (unless (-filter 'dap--session-running (dap--get-sessions))
          (and (get-buffer dap-ui--sessions-buffer)
              (kill-buffer dap-ui--sessions-buffer))
          (and (get-buffer dap-ui--locals-buffer)
              (kill-buffer dap-ui--locals-buffer))))
:config
    (add-hook 'dap-terminated-hook 'my/hide-debug-windows)
    (add-hook 'dap-stopped-hook 'my/show-debug-windows)
)

(use-package lsp-grammarly :disabled
:hook (text-mode . (lambda () (require 'lsp-grammarly) (lsp)))
)

(use-package consult-lsp :requires (lsp-mode consult)
    :after (lsp-mode consult)
    :bind (:map lsp-mode-map
            ([remap xref-find-apropos] . consult-lsp-symbols))
    :general (leader
                 "ls" 'consult-lsp-symbols
                 "lf" 'consult-lsp-file-symbols
                 "ld" 'consult-lsp-diagnostics)
    )

(use-package eglot :after (exec-path-from-shell projectile) :disabled
    :preface
    (defun my/eglot-ensure ()
        (require 'exec-path-from-shell)
        (exec-path-from-shell-initialize)
        (eglot-ensure))
    :hook (
          (rust-mode   . my/eglot-ensure)
          (go-mode     . my/eglot-ensure)
          (nix-mode    . my/eglot-ensure)
          (python-base-mode . my/eglot-ensure)
          
)
    :config
    (add-to-list 'eglot-server-programs
                '((rust-ts-mode rust-mode) .
                     ("rust-analyzer"
                         :initializationOptions
                         (:check (:command "clippy")
                          :procMacro (:enable t)
                          :diagnostics (:disabled ["unresolved-import"])
                          :inlayHint (:parameterHints (:enable nil)
                                      :typeHints (:enable nil)
                                      :chainingHints (:enable nil)))
                         )))
    (add-to-list 'eglot-server-programs '(nix-mode . ("nil")))
    )

(use-package eglot-x :ensure (:host github :repo "nemethf/eglot-x") :disabled
    :after eglot
    :config (eglot-x-setup)
    )

(use-package flycheck-eglot :after (flycheck eglot)
    :functions (flycheck-eglot-mode)
    :config (flycheck-eglot-mode)
    )

(use-package eldoc-box :after eglot
    :hook (eglot-managed-mode . eldoc-box-hover-at-point-mode)
          ;(eglot-managed-mode . eldoc-box-hover-mode)
    :custom (eldoc-box-clear-with-C-g t)
            (eldoc-box-offset 1)
    :config (add-to-list 'eldoc-box-frame-parameters '(alpha . 0.80))
    )

;; need to install https://github.com/blahgeek/emacs-lsp-booster
(use-package eglot-booster :ensure (:host github :repo "jdtsmith/eglot-booster")
    :after eglot
    :config (eglot-booster-mode)
    )

(use-package consult-eglot :after eglot)

(use-package lsp-bridge :after exec-path-from-shell :disabled
    :ensure (:host github
             :repo "manateelazycat/lsp-bridge"
             :files (:defaults ("*.el" "*.py" "acm" "core"
                                "langserver" "multiserver" "resources"))
             :build (:not elpaca--byte-compile)
             )
    :init
    ;; (setq lsp-bridge-enable-log nil)
    (global-lsp-bridge-mode)
    (add-hook 'envrc-mode-hook 'lsp-bridge-restart-process)
    )

(use-package lsp-key-map :no-require t :ensure nil :after (:any lsp-mode eglot)
:preface
    (defun lsp-key-mapper (lsp-func eglot-func)
        (if (and (bound-and-true-p lsp-mode) (fboundp lsp-func))
            (call-interactively lsp-func)
            (if (and (bound-and-true-p eglot--managed-mode) (fboundp eglot-func))
                (call-interactively eglot-func)
            (message "No LSP client available for code actions"))))

    (defun lsp-key-map-code-action ()
        (interactive)
        (lsp-key-mapper 'lsp-execute-code-action 'eglot-code-actions))

    (defun lsp-key-map-find-definition ()
        (interactive)
        (lsp-key-mapper 'lsp-find-definition 'xref-find-declaration))

    (defun lsp-key-map-find-implementation ()
        (interactive)
        (lsp-key-mapper 'lsp-find-implementation 'eglot-find-implementation))

    (defun lsp-key-map-find-references ()
        (interactive)
        (lsp-key-mapper 'lsp-find-references 'eglot-x-find-refs))

    (defun lsp-key-map-find-typeDefinition ()
        (interactive)
        (lsp-key-mapper 'lsp-find-typeDefinition 'eglot-find-typeDefinition))

    (defun lsp-key-map-rename ()
        (interactive)
        (lsp-key-mapper 'lsp-rename 'eglot-rename))

:general (leader "hh" '(lsp-key-map-code-action         :wk "wizard")
                 "pp" '(xref-go-back                    :wk "lsp pop")
                 "fd" '(lsp-key-map-find-definition     :wk "lsp define")
                 "fT" '(lsp-key-map-find-typeDefinition :wk "lsp type")
                 "fi" '(lsp-key-map-find-implementation :wk "lsp implementation")
                 "fr" '(lsp-key-map-find-references     :wk "lsp ref")
                 "lr" '(lsp-key-map-rename              :wk "lsp rename"))
    )

(provide '+lsp)
;;; +lsp.el ends here
