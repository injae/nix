;;; +ssh.el --- Summery -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(use-package ssh-config-mode
:config (add-to-list 'auto-mode-alist '("/\\.ssh/config\\'" . ssh-config-mode))
)

(provide '+ssh)
;;; +ssh.el ends here
