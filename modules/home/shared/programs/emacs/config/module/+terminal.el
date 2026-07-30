;;; +terminal.el --- Summery -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(use-package vterm-hangul :ensure nil :load-path "~/.emacs.d/lisp/vterm-hangul/" :after vterm
    :config (vterm-hangul-setup))

(use-package vterm :after (evil-collection exec-path-from-shell)
;:custom (vterm-always-compile-module t)
:config
    (add-hook 'vterm-mode-hook (lambda () (display-line-numbers-mode -1)))
    (add-hook 'vterm-mode-hook (lambda ()
      (ligature-mode -1)
      (face-remap-add-relative 'default :family "Sarasa Term K" :height 160)))
    (add-hook 'vterm-mode-hook #'evil-collection-vterm-escape-stay)
    ;; Match vterm-color-black background to Emacs default background.
    ;; Opencode/Claude Code use ANSI black (#0) as background for UI
    ;; elements; without this, it renders as gray and clashes with the
    ;; Emacs theme.
    (let ((bg (face-background 'default nil t)))
      (set-face-background 'vterm-color-black bg)
      (set-face-foreground 'vterm-color-black bg))
)


(use-package ghostel :after exec-path-from-shell
:custom (ghostel-term "xterm-ghostty")
        ;; Keep the downloaded native module outside the elpaca build directory
        ;; so it survives a package rebuild.
        (ghostel-module-directory (no-littering-expand-var-file-name "ghostel/"))
:config
    (add-hook 'ghostel-mode-hook (lambda () (display-line-numbers-mode -1)))
    (add-hook 'ghostel-mode-hook (lambda ()
      (ligature-mode -1)
      (face-remap-add-relative 'default :family "Sarasa Term K" :height 160)))
    ;; Match ghostel-color-black to the Emacs background, same reason as
    ;; `vterm-color-black' above.
    (let ((bg (face-background 'default nil t)))
      (set-face-background 'ghostel-color-black bg)
      (set-face-foreground 'ghostel-color-black bg))
)

;; Lisp input methods (hangul) commit through `self-insert-command', which
;; bypasses ghostel's key remapping; ghostel-ime forwards the committed text to
;; the PTY.  Ships inside the ghostel package, so no separate recipe.
(use-package ghostel-ime :ensure nil :after ghostel
:hook (ghostel-mode . ghostel-ime-mode)
)

(use-package evil-ghostel :after (ghostel evil)
:hook (ghostel-mode . evil-ghostel-mode)
)

(defun +terminal--shell-pop-type (backend)
  "Return a `shell-pop-shell-type' value for BACKEND."
  (pcase backend
    ('vterm '("vterm" "*vterm*"
              (lambda () (let ((vterm-shell shell-pop-term-shell)) (vterm)))))
    ('ghostel '("ghostel" "*ghostel*"
                (lambda () (let ((ghostel-shell shell-pop-term-shell)) (ghostel)))))))

(defun +terminal--root ()
  "Return the project root, or `default-directory' outside a project."
  (or (and (fboundp 'projectile-project-root) (projectile-project-root))
      default-directory))

(defcustom +terminal-backend 'vterm
  "Terminal emulator opened by `+terminal-new' and `+terminal-shell-pop'.
Setting this through Customize reconfigures `shell-pop-shell-type'."
  :type '(choice (const vterm) (const ghostel))
  :group 'shell-pop
  ;; Do not call :set while loading: `shell-pop' is not available yet.
  :initialize #'custom-initialize-default
  :set (lambda (sym val)
         (set-default sym val)
         (customize-set-variable 'shell-pop-shell-type
                                 (+terminal--shell-pop-type val))))

(defun +terminal-toggle-backend ()
  "Toggle `+terminal-backend' between vterm and ghostel."
  (interactive)
  (customize-set-variable '+terminal-backend
                          (if (eq +terminal-backend 'ghostel) 'vterm 'ghostel))
  (message "terminal backend: %s" +terminal-backend))

(defun +terminal-new (&optional arg)
  "Open a terminal in the project root using `+terminal-backend'.
Without ARG a fresh terminal buffer is created; with a numeric ARG switch to
the terminal with that number, creating it when needed."
  (interactive "P")
  (let ((default-directory (+terminal--root)))
    (pcase +terminal-backend
      ('ghostel (ghostel (or arg t)))
      ('vterm (vterm (or arg t))))))

(use-package shell-pop
:preface
    (defun +terminal-shell-pop (arg)
      "Pop a terminal in the project root, or in `default-directory' outside a project.
ARG is passed through to `shell-pop'."
      (interactive "P")
      (let ((default-directory (+terminal--root)))
        (shell-pop arg)))
:general (leader "ut" '+terminal-shell-pop :wk "toggle terminal")
         (leader "tn" '+terminal-new :wk "new terminal")
:custom (shell-pop-window-size 30)
        (shell-pop-window-position "bottom")
        (shell-pop-full-span nil)
        (shell-pop-shell-type (+terminal--shell-pop-type +terminal-backend))
)

(use-package powershell)

(provide '+terminal)
;;; +terminal.el ends here
