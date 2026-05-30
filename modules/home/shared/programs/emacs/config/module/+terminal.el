;;; +terminal.el --- Summery -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(declare-function claude-code-ide-session-buffer-p "claude-code-ide" (buffer))

(defvar +vterm--hangul-captured ""
  "Characters captured from hangul self-insert-command during vterm composition.")

(defvar-local +vterm--hangul-has-preedit nil
  "Non-nil when this vterm buffer has a pending preedit character.")

(defun +vterm--hangul-capture-self-insert (_n &optional char)
  "Capture self-insert-command output during per-keystroke hangul composition."
  (let ((c (or char (and (characterp last-command-event) last-command-event))))
    (when c
      (setq +vterm--hangul-captured
            (concat +vterm--hangul-captured (char-to-string c))))))

(defun +vterm--hangul-flush ()
  "Commit any pending hangul preedit syllable to vterm."
  (when (and +vterm--hangul-has-preedit
             (boundp 'hangul-queue)
             hangul-queue
             (not (seq-every-p #'zerop hangul-queue)))
    (let ((+vterm--hangul-captured ""))
      (cl-letf (((symbol-function 'self-insert-command) #'+vterm--hangul-capture-self-insert)
                ((symbol-function 'quail-delete-region) #'ignore)
                ((symbol-function 'move-overlay) #'ignore))
        (hangul-insert-character hangul-queue))
      (when (> (length +vterm--hangul-captured) 0)
        (vterm-send-string +vterm--hangul-captured)))
    (setq +vterm--hangul-has-preedit nil)
    (setq hangul-queue (make-vector 6 0))
    (message "")))

(defun +vterm--self-insert-with-im (orig-fn)
  "Around advice for `vterm--self-insert' supporting Emacs hangul input.
Calls hangul2-input-method-internal per keystroke so each committed
syllable is sent to the terminal immediately."
  (if (and vterm--term
           input-method-function
           (characterp last-command-event)
           (not (memq 'meta (event-modifiers last-command-event)))
           (not (memq 'control (event-modifiers last-command-event))))
      (let ((key (event-basic-type last-command-event)))
        (require 'hangul)
        (if (hangul-alphabetp key)
            ;; Hangul key: advance composition by exactly one step.
            ;; Use last-command-event (not key) to preserve shift for ㄲ/ㅆ/ㅃ etc.
            (let ((+vterm--hangul-captured ""))
              (unless (and (boundp 'quail-overlay) (overlayp quail-overlay))
                (setq quail-overlay (make-overlay (point) (point) nil t t)))
              (cl-letf (((symbol-function 'self-insert-command) #'+vterm--hangul-capture-self-insert)
                        ((symbol-function 'quail-delete-region) #'ignore)
                        ((symbol-function 'move-overlay) #'ignore))
                (hangul2-input-method-internal last-command-event))
              (let ((captured +vterm--hangul-captured))
                ;; hangul-insert-character inserts N chars per call.
                ;; Last char is always preedit; everything before is committed.
                (when (> (length captured) 1)
                  (vterm-send-string (substring captured 0 -1)))
                (if (> (length captured) 0)
                    (progn
                      (setq +vterm--hangul-has-preedit t)
                      (message "[ %s ]" (substring captured -1)))
                  (setq +vterm--hangul-has-preedit nil)
                  (message ""))))
          ;; Backspace with pending preedit: decompose one step (까→ㄲ→∅).
          (if (and (or (eq key 'backspace)
                       (and (integerp key) (or (= key ?\d) (= key ?\^H))))
                   +vterm--hangul-has-preedit)
              (let ((+vterm--hangul-captured ""))
                (cl-letf (((symbol-function 'self-insert-command) #'+vterm--hangul-capture-self-insert)
                          ((symbol-function 'delete-backward-char) #'ignore)
                          ((symbol-function 'delete-char) #'ignore)
                          ((symbol-function 'quail-delete-region) #'ignore)
                          ((symbol-function 'move-overlay) #'ignore))
                  (hangul-delete-backward-char))
                (if (> (length +vterm--hangul-captured) 0)
                    (progn
                      (setq +vterm--hangul-has-preedit t)
                      (message "[ %s ]" +vterm--hangul-captured))
                  (setq +vterm--hangul-has-preedit nil)
                  (message "")))
            ;; Other non-hangul key (including space): flush pending preedit first,
            ;; then send key. Matches standard Korean IME behavior (가+space → "가 ").
            (+vterm--hangul-flush)
            (let ((input-method-function nil))
              (funcall orig-fn)))))
    (funcall orig-fn)))

(defun +vterm-toggle-korean ()
  "Toggle Korean hangul input method in vterm buffer."
  (interactive)
  (require 'hangul)
  (if input-method-function
      (progn
        (+vterm--hangul-flush)
        (setq-local input-method-function nil)
        (setq-local current-input-method nil)
        (when (boundp 'evil-input-method) (setq-local evil-input-method nil))
        (setq +vterm--hangul-has-preedit nil)
        (setq hangul-queue (make-vector 6 0))
        (force-mode-line-update)
        (message "Korean input: OFF"))
    (setq +vterm--hangul-has-preedit nil)
    (setq hangul-queue (make-vector 6 0))
    (setq-local input-method-function #'hangul2-input-method)
    (setq-local current-input-method "korean-hangul")
    ;; Tell evil to restore Korean on insert state re-entry.
    (when (boundp 'evil-input-method) (setq-local evil-input-method "korean-hangul"))
    (force-mode-line-update)
    (message "Korean input: ON 한2")))

(use-package vterm :after (evil-collection exec-path-from-shell)
;:custom (vterm-always-compile-module t)
:config
    (add-hook 'vterm-mode-hook (lambda () (display-line-numbers-mode -1)))
    (add-hook 'vterm-mode-hook #'evil-collection-vterm-escape-stay)
    (advice-add 'vterm--self-insert :around #'+vterm--self-insert-with-im)
    (dolist (key '("C-'" "S-SPC" "<f17>" "<Hangul>"))
      (add-to-list 'vterm-keymap-exceptions key))
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
