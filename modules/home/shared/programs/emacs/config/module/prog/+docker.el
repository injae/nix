;;; +docker.el --- Summery -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(use-package docker
:commands docker
:general (leader "hud" 'docker)
:custom (docker-image-run-arguments '("-i", "-t", "--rm"))
)

(use-package dockerfile-mode
:mode ("Dockerfile\\'" . dockerfile-mode)
)

(use-package docker-compose-mode)

(use-package kubel :after vterm
    :commands (kubel)
    :config (kubel-vterm-setup)
    )
(use-package kubel-evil :after (kubel evil))

(use-package k8s-mode :after yasnippet
    :hook (k8s-mode . yas-minor-mode)
    )

(use-package kubedoc)

(provide '+docker)
;;; +docker.el ends here
