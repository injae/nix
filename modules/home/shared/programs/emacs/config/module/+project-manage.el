;;; +project-manage.el --- Summery -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(use-package projectile :after (evil exec-path-from-shell)
:config
    ;(setq projectile-require-project-root nil)
	;(setq projectile-current-project-on-switch t)
	;; Cache the per-project file list so `projectile-project-files' is not
	;; re-indexed on every call (eldoc/modeline/completion hammer it).  This
	;; is what surfaces the recurring "Projectile is indexing ..." stall.
	(setq projectile-enable-caching t)
	;; Git indexing here is instant (82 files); the async progress-reporter
	;; loop only adds `accept-process-output' churn.  Run it synchronously.
	(setq projectile-async-indexing nil)
	(setq projectile-globally-ignored-directories
        (append '("^\\eln-cache$") projectile-globally-ignored-directories))
	(evil-ex-define-cmd "kp" 'projectile-kill-buffers)
    (projectile-register-project-type 'bazel '("WORKSPACE")
                                    :project-file "WORKSPACE"
                                    :compile "bazel build"
                                    :test "bazel test"
                                    :run "bazel run")
    (add-hook 'projectile-before-switch-project-hook (lambda () (exec-path-from-shell-initialize)))
    (projectile-mode)
)

(use-package projection :after (evil exec-path-from-shell)
    :hook ((after-init . global-projection-hook-mode)
           (compilation-mode . projection-customize-compilation-mode))
    :custom (compilation-buffer-name-function #'projection-customize-compilation-buffer-name-function)
    :config (with-eval-after-load 'project (require 'projection))
    )

(use-package projection-multi :after projection
    :bind (:map project-prefix-map
              ("RET" . projection-multi-compile)))

(use-package projection-multi-embark :after (projection-multi embark)
    :config (projection-multi-embark-setup-command-map)
    )

(provide '+project-manage)
;;; +project-manage.el ends here
