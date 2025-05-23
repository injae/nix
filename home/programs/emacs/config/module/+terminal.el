;;; +terminal.el --- Summery -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(use-package vterm :after (evil-collection exec-path-from-shell projectile)
;:custom (vterm-always-compile-module t)
:config
    (add-hook 'vterm-mode-hook (lambda () (display-line-numbers-mode -1)))
    (add-hook 'vterm-mode-hook
            (lambda ()
                (set (make-local-variable 'buffer-face-mode-face) 'fixed-pitch)
                    (buffer-face-mode t)))
    (add-hook 'vterm-mode-hook #'evil-collection-vterm-escape-stay)
)


(use-package multi-vterm :after vterm
:general (leader "tn" 'multi-vterm :wk "new terminal")
)

(use-package vterm-with-centaur-tab :no-require t :ensure nil :disabled
:after (vterm-toggle centaur-tabs)
:preface
    (defun vmacs-awesome-tab-buffer-groups ()
          "`vmacs-awesome-tab-buffer-groups' control buffers' group rules. "
          (list
           (cond
            ((derived-mode-p 'eshell-mode 'term-mode 'shell-mode 'vterm-mode) "Term")
            ((string-match-p (rx (or "\*Helm"
                                     "\*helm"
                                     "\*tramp"
                                     "\*Completions\*"
                                     "\*sdcv\*"
                                     "\*Messages\*"
                                     "\*Ido Completions\*"))
                                     (buffer-name))
             "Emacs")
            (t "Common"))))
    (defun vmacs-term-mode-p(&optional args)
        (derived-mode-p 'eshell-mode 'term-mode 'shell-mode 'vterm-mode))
:config (setq centaur-tabs-buffer-groups-function   'vmacs-awesome-tab-buffer-groups)
        (setq vterm-toggle--vterm-buffer-p-function 'vmacs-term-mode-p)
)

(use-package vterm-toggle :after vterm
    :preface
    (defun custom-vterm-toggle-cd-show ()
        (interactive)
        (vterm-toggle-cd)
        (vterm-toggle-insert-cd))
    :general (leader "ut" 'custom-vterm-toggle-cd-show :wk "toggle terminal")
    :custom (vterm-toggle-projectile-root t)
    :config
    (setq vterm-toggle-fullscreen-p nil)
    (add-to-list 'display-buffer-alist
                '((lambda (buffer-or-name _)
                    (let ((buffer (get-buffer buffer-or-name)))
                        (with-current-buffer buffer
                        (or (equal major-mode 'vterm-mode)
                            (string-prefix-p vterm-buffer-name (buffer-name buffer))))))
                    (display-buffer-reuse-window display-buffer-at-bottom)
                    ;;(display-buffer-reuse-window display-buffer-in-direction)
                    ;;display-buffer-in-direction/direction/dedicated is added in emacs27
                    ;;(direction . bottom)
                    ;;(dedicated . t) ;dedicated is supported in emacs27
                    (reusable-frames . visible)
                    (window-height . 0.3)))
    )

(use-package vterm-command :no-require t :ensure nil
:after (vterm projectile)
:preface
(defun run-in-vterm-kill (process event)
  "A process sentinel. Kill PROCESS's buffer if it is live."
  (let ((b (process-buffer process)))
    (and (buffer-live-p b)
         (kill-buffer b))))

(defun run-in-vterm (command)
  "Execute string COMMAND in a new vterm.
Interactively, prompt for COMMAND with the current buffer's file name supplied.
When called from Dired, supply the name of the file at point.
Like `async-shell-command`, but run in a vterm for full terminal features.
The new vterm buffer is named in the form `*foo bar.baz*`, the
command and its arguments in earmuffs.
When the command terminates, the shell remains open, but when the
shell exits, the buffer is killed."
  (interactive
   (list
    (let* ((f (cond (buffer-file-name)
                    ((eq major-mode 'dired-mode)
                     (dired-get-filename nil t))))
           (filename (concat " " (shell-quote-argument (and f (file-relative-name f))))))
      (read-shell-command "Terminal command: "
                          (cons filename 0)
                          (cons 'shell-command-history 1)
                          (list filename)))))
  (with-current-buffer (vterm (concat "*" command "*"))
    (set-process-sentinel vterm--process #'run-in-vterm-kill)
    (vterm-send-string command)
    (vterm-send-return)))
)

(use-package powershell)

(provide '+terminal)
;;; +terminal.el ends here
