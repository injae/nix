;;; +lsp.el --- Summery -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(use-package treemacs :disabled :config (setq treemacs-resize-icons 22))
(use-package treemacs-evil :after (treemacs evil))
(use-package treemacs-projectile :after (treemacs projectile))

(use-package sideline-eglot :disabled
    :init (setq sideline-backends-right '(sideline-eglot))
    )

(use-package eglot :no-require t :ensure nil :after (exec-path-from-shell projectile)
    :preface
    (defun my/eglot-eldoc ()
        (setq eldoc-documentation-strategy
                'eldoc-documentation-compose-eagerly))
    (defun my/eglot-ensure ()
        (interactive)
        (exec-path-from-shell-initialize)
        (eglot-ensure))
    :hook (eglot-managed-mode . my/eglot-eldoc)
    :custom (eglot-code-action-indications '(mode-line left-fringe margin))
    :config
    (defvar my/eglot-format-on-save-modes
        '(go-ts-mode rust-ts-mode nix-ts-mode python-ts-mode))
    (defun my/eglot-format-on-save ()
        (when (and (eglot-managed-p)
                   (apply #'derived-mode-p my/eglot-format-on-save-modes))
            (eglot-format-buffer)))
    (add-hook 'before-save-hook #'my/eglot-format-on-save)
    (add-to-list 'eglot-server-programs '((go-mode go-dot-mod-mode go-dot-work-mode go-ts-mode go-mod-ts-mode) . ("rass" "go")))
    (add-to-list 'eglot-server-programs '((yaml-ts-mode yaml-mode) . ("rass" "yaml")))
    (add-to-list 'eglot-server-programs '((rust-ts-mode rust-mode) . ("rass" "rust")))
    (add-to-list 'eglot-server-programs '(nix-ts-mode  . ("rass" "nix")))
    (add-to-list 'eglot-server-programs '(nix-mode     . ("rass" "nix")))
    (add-to-list 'eglot-server-programs '(markdown-ts-mode . ("marksman" "server")))

    ;; On reconnect eglot re-syncs every managed buffer.  Buffers whose file
    ;; was renamed or deleted externally (git mv, refactor tools) otherwise
    ;; keep feeding stale content to the language server, so it reports
    ;; symbols from files that no longer exist -- even across eglot-shutdown
    ;; / reconnect.  After connecting, drop such buffers from the server
    ;; (sends didClose, no kill) and report them.
    (defun my/eglot-exclude-deleted-file-buffers (server)
        "Unmanage SERVER buffers whose file no longer exists, and report them."
        (let ((gone (seq-filter
                     (lambda (buf)
                         (let ((f (buffer-local-value 'buffer-file-name buf)))
                             (and f
                                  (not (file-remote-p f))
                                  (not (file-exists-p f)))))
                     (eglot--managed-buffers server))))
            (dolist (buf gone)
                (with-current-buffer buf (eglot--managed-mode -1)))
            (when gone
                (message "eglot: excluded %d deleted-file buffer(s): %s"
                         (length gone)
                         (mapconcat #'buffer-name gone ", ")))))
    (add-hook 'eglot-connect-hook #'my/eglot-exclude-deleted-file-buffers)

    ;; macOS pins Emacs at 1024 open file descriptors: `init_process_emacs'
    ;; clamps RLIMIT_NOFILE down to FD_SETSIZE and `inrange_fd' closes
    ;; anything above it, so raising the system limit cannot lift this.  The
    ;; kqueue file-notify backend spends one descriptor per watched
    ;; directory, and for a `baseUri' outside the project root
    ;; `eglot--watch-globs' enumerates subdirectories with plain `find',
    ;; ignoring VCS ignores.  A python server pointing at a /nix/store
    ;; site-packages tree therefore exhausts the descriptors and every watch
    ;; fails with "Opening directory: Too many open files".  Skip trees that
    ;; cannot change (the nix store is read-only) or hold no source
    ;; (__pycache__); .venv and node_modules stay watched because
    ;; dependencies there really do change.
    (defvar my/eglot-watch-exclude-regexp
        (rx (or "/nix/store/" "/__pycache__/"))
        "Regexp matching directory trees eglot must not file-watch.")

    (defun my/eglot-skip-unwatchable-dir (fn server id globs dir &rest rest)
        "Call FN unless DIR matches `my/eglot-watch-exclude-regexp'.
SERVER, ID, GLOBS and REST are passed through to FN unchanged."
        (unless (and dir
                     (string-match-p my/eglot-watch-exclude-regexp
                                     (file-name-as-directory dir)))
            (apply fn server id globs dir rest)))
    (advice-add 'eglot--watch-globs :around #'my/eglot-skip-unwatchable-dir)

    ;; Second line of defence: eglot's cap must sit inside the 1024
    ;; descriptor budget, or the default 10000 lets `file-notify-add-watch'
    ;; fail with EMFILE before eglot ever warns.
    (setq eglot-max-file-watches 600)
    )

(use-package eglot-x :ensure (:host github :repo "nemethf/eglot-x")
    :after eglot
    :config
    (eglot-x-setup)
    ;; Compat shim: Emacs 31's bundled eglot changed
    ;; `eglot--apply-workspace-edit' to (SERVER WEDIT ORIGIN), but eglot-x
    ;; still calls it with two args, so applying an edit-producing code
    ;; action fails with "Wrong number of arguments ... 2".  Re-define the
    ;; `:around' method with SERVER threaded through until upstream catches up.
    (cl-defmethod eglot-execute :around (server action)
        "Execute ACTION locally if possible, otherwise ask SERVER to execute it."
        (if (not eglot-x-client-commands)
            (cl-call-next-method)
            (eglot--dcase action
                (((Command)) (eglot-x-execute-command server action))
                (((CodeAction) edit command data)
                 (if (and (null edit) (null command) data
                          (eglot-server-capable :codeActionProvider :resolveProvider))
                     (eglot-execute server
                                    (eglot--request server :codeAction/resolve action))
                     (when edit (eglot--apply-workspace-edit server edit this-command))
                     (when command
                         (eglot-x-execute-command server command)))))))
    )

(use-package consult-eglot :after eglot)

(use-package lsp-key-map :no-require t :ensure nil :after eglot
:preface
    (defun lsp-key-mapper (lsp-func eglot-func)
        (if (and (bound-and-true-p lsp-mode) (fboundp lsp-func))
            (call-interactively lsp-func)
            (if (and (eglot-managed-p) (fboundp eglot-func))
                (call-interactively eglot-func)
            (message "No LSP client available for code actions"))))

    (defun lsp-key-map-code-action ()
        (interactive)
        (lsp-key-mapper 'lsp-execute-code-action 'eglot-code-actions))

    (defun lsp-key-map-find-definition ()
        (interactive)
        (lsp-key-mapper 'lsp-find-definition 'xref-find-definitions))

    (defun lsp-key-map-find-implementation ()
        (interactive)
        (lsp-key-mapper 'lsp-find-implementation 'eglot-find-implementation))

    (defun lsp-key-map-find-references ()
        (interactive)
        (lsp-key-mapper 'lsp-find-references 'xref-find-references))

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
