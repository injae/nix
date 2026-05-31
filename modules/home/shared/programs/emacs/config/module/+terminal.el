;;; +terminal.el --- Summery -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(declare-function claude-code-ide-session-buffer-p "claude-code-ide" (buffer))
(defvar quail-overlay)

(defvar +vterm--hangul-captured ""
  "Characters captured from hangul self-insert-command during vterm composition.")

(defvar-local +vterm--hangul-preedit-sent ""
  "Preedit character currently displayed inline in the vterm terminal.")

(defvar-local +vterm--hangul-active nil
  "Non-nil when Korean hangul input is active in this vterm buffer.")

(defun +vterm--hangul-capture-self-insert (_n &optional char)
  "Capture self-insert-command output during per-keystroke hangul composition."
  (let ((c (or char (and (characterp last-command-event) last-command-event))))
    (when c
      (setq +vterm--hangul-captured
            (concat +vterm--hangul-captured (char-to-string c))))))

(defun +vterm--hangul-erase-preedit ()
  "Erase the inline preedit character from the vterm terminal."
  (when (> (length +vterm--hangul-preedit-sent) 0)
    (vterm-send-string "\177")
    (setq +vterm--hangul-preedit-sent "")))

(defun +vterm--hangul-flush ()
  "Commit pending preedit: already inline in terminal, just clear tracking state."
  (when (> (length +vterm--hangul-preedit-sent) 0)
    (setq +vterm--hangul-preedit-sent "")
    (setq hangul-queue (make-vector 6 0))))

(defun +vterm--after-evil-insert-clear-imf ()
  "Clear input-method-function after evil restores it on insert state entry.
Evil calls activate-input-method which sets input-method-function; that causes
hangul2-input-method to be invoked by the event loop, inserting directly into
the vterm buffer. This hook clears it so our advice remains the sole handler."
  (when +vterm--hangul-active
    (setq input-method-function nil)))

(defun +vterm--hangul-compose-key (event)
  "Advance hangul2 composition one step for EVENT, update inline preedit.
EVENT is last-command-event; passed directly to preserve shift for ㄲ/ㅆ/ㅃ."
  (unless (and (boundp 'quail-overlay) (overlayp quail-overlay))
    (setq quail-overlay (make-overlay (point) (point) nil t t)))
  (let ((+vterm--hangul-captured ""))
    (cl-letf (((symbol-function 'self-insert-command) #'+vterm--hangul-capture-self-insert)
              ((symbol-function 'quail-delete-region) #'ignore)
              ((symbol-function 'move-overlay) #'ignore))
      (hangul2-input-method-internal event))
    (let ((captured +vterm--hangul-captured))
      (+vterm--hangul-erase-preedit)
      (when (> (length captured) 1)
        (vterm-send-string (substring captured 0 -1)))
      (if (> (length captured) 0)
          (progn
            (vterm-send-string (substring captured -1))
            (setq +vterm--hangul-preedit-sent (substring captured -1)))
        (setq +vterm--hangul-preedit-sent "")))))

(defun +vterm--hangul-decompose-backspace ()
  "Decompose current preedit one step via hangul-delete-backward-char."
  (let ((+vterm--hangul-captured ""))
    (cl-letf (((symbol-function 'self-insert-command) #'+vterm--hangul-capture-self-insert)
              ((symbol-function 'delete-backward-char) #'ignore)
              ((symbol-function 'delete-char) #'ignore)
              ((symbol-function 'quail-delete-region) #'ignore)
              ((symbol-function 'move-overlay) #'ignore))
      (hangul-delete-backward-char))
    (+vterm--hangul-erase-preedit)
    (if (> (length +vterm--hangul-captured) 0)
        (progn
          (vterm-send-string +vterm--hangul-captured)
          (setq +vterm--hangul-preedit-sent +vterm--hangul-captured))
      (setq +vterm--hangul-preedit-sent ""))))

(defun +vterm--self-insert-with-im (orig-fn)
  "Around advice for `vterm--self-insert' supporting Emacs hangul input.
Calls hangul2-input-method-internal per keystroke so each committed
syllable is sent to the terminal immediately."
  (if (and vterm--term
           +vterm--hangul-active
           (characterp last-command-event)
           (not (memq 'meta (event-modifiers last-command-event)))
           (not (memq 'control (event-modifiers last-command-event))))
      (let ((key (event-basic-type last-command-event)))
        (require 'hangul)
        (cond
         ((hangul-alphabetp key)
          (+vterm--hangul-compose-key last-command-event))
         ((and (or (eq key 'backspace)
                   (and (integerp key) (or (= key ?\d) (= key ?\^H))))
               (> (length +vterm--hangul-preedit-sent) 0))
          (+vterm--hangul-decompose-backspace))
         (t
          (+vterm--hangul-flush)
          (let ((input-method-function nil))
            (funcall orig-fn)))))
    (funcall orig-fn)))

(defun +vterm--send-backspace-with-im (orig-fn)
  "Around advice for `vterm-send-backspace' supporting hangul decompose.
When Korean is active and preedit exists, decompose one jaso step instead of
sending a raw backspace to the terminal."
  (if (and vterm--term +vterm--hangul-active)
      (if (> (length +vterm--hangul-preedit-sent) 0)
          (+vterm--hangul-decompose-backspace)
        (funcall orig-fn))
    (funcall orig-fn)))

(defun +vterm--send-return-flush-im (orig-fn)
  "Around advice for `vterm-send-return' to flush pending hangul preedit.
The preedit char is already inline in the terminal and becomes committed text;
this clears tracking state before Enter is sent."
  (when (and vterm--term +vterm--hangul-active)
    (+vterm--hangul-flush))
  (funcall orig-fn))

(defun +vterm-toggle-korean ()
  "Toggle Korean hangul input method in vterm buffer."
  (interactive)
  (require 'hangul)
  (if +vterm--hangul-active
      (progn
        (+vterm--hangul-flush)
        (setq-local +vterm--hangul-active nil)
        (setq-local current-input-method nil)
        (setq-local input-method-function nil)
        (when (boundp 'evil-input-method) (setq-local evil-input-method nil))
        (when (boundp 'evil-insert-state-entry-hook)
          (remove-hook 'evil-insert-state-entry-hook
                       #'+vterm--after-evil-insert-clear-imf t))
        (kill-local-variable 'hangul-queue)
        (force-mode-line-update)
        (message "Korean input: OFF"))
    (setq +vterm--hangul-preedit-sent "")
    (make-local-variable 'hangul-queue)
    (setq hangul-queue (make-vector 6 0))
    (setq-local +vterm--hangul-active t)
    (setq-local current-input-method "korean-hangul")
    (setq-local input-method-function nil)
    (when (boundp 'evil-insert-state-entry-hook)
      (add-hook 'evil-insert-state-entry-hook
                #'+vterm--after-evil-insert-clear-imf t t))
    (force-mode-line-update)
    (message "Korean input: ON 한2")))

(use-package vterm :after (evil-collection exec-path-from-shell)
;:custom (vterm-always-compile-module t)
:config
    (add-hook 'vterm-mode-hook (lambda () (display-line-numbers-mode -1)))
    (add-hook 'vterm-mode-hook #'evil-collection-vterm-escape-stay)
    (advice-add 'vterm--self-insert  :around #'+vterm--self-insert-with-im)
    (advice-add 'vterm-send-backspace :around #'+vterm--send-backspace-with-im)
    (advice-add 'vterm-send-return   :around #'+vterm--send-return-flush-im)
    (dolist (key '("C-'" "S-SPC" "<f17>" "<Hangul>"))
      (add-to-list 'vterm-keymap-exceptions key))
    (define-key vterm-mode-map (kbd "C-'")      #'+vterm-toggle-korean)
    (define-key vterm-mode-map (kbd "<Hangul>") #'+vterm-toggle-korean)
    ;; Match vterm-color-black background to Emacs default background.
    ;; Opencode/Claude Code use ANSI black (#0) as background for UI
    ;; elements; without this, it renders as gray and clashes with the
    ;; Emacs theme.
    (let ((bg (face-background 'default nil t)))
      (set-face-background 'vterm-color-black bg)
      (set-face-foreground 'vterm-color-black bg))
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
    (add-to-list 'vterm-toggle-togglable-buffer-functions
                 (lambda (buf)
                   (if (fboundp 'claude-code-ide-session-buffer-p)
                       (not (claude-code-ide-session-buffer-p buf))
                     t)))
    (add-to-list 'display-buffer-alist
                '((lambda (buffer-or-name _)
                    (let ((buffer (get-buffer buffer-or-name)))
                        (with-current-buffer buffer
                        (or (equal major-mode 'vterm-mode)
                            (string-prefix-p vterm-buffer-name (buffer-name buffer))))))
                    (display-buffer-reuse-window display-buffer-at-bottom)
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
