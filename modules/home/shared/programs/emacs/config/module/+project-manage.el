;;; +project-manage.el --- Summery -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(use-package projectile :after (evil exec-path-from-shell)
:config
    ;(setq projectile-require-project-root nil)
	;(setq projectile-enable-caching t)
	;(setq projectile-current-project-on-switch t)
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
