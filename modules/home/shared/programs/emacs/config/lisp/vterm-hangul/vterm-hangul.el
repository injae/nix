;;; vterm-hangul.el --- Korean Hangul input patch for vterm -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(require 'quail)
(load "quail/hangul" nil t)

(defvar quail-overlay)

(defvar +vterm--hangul-captured ""
  "Characters captured from hangul self-insert-command during vterm composition.")

(defvar-local +vterm--hangul-preedit-sent ""
  "Preedit character currently displayed inline in the vterm terminal.")

(defvar-local +vterm--hangul-active nil
  "Non-nil when Korean hangul input is active in this vterm buffer.")

(defcustom +vterm-hangul-toggle-keys '("C-'" "<Hangul>")
  "Keys bound to `+vterm-toggle-korean' in `vterm-mode-map'.
Each key is also added to `vterm-keymap-exceptions' so vterm passes it to Emacs."
  :type '(repeat string)
  :group 'vterm)

(defconst +vterm--hangul-queue-length 6
  "Length of the hangul state vector used by hangul2 input method.")

(defun +vterm--hangul-preedit-p ()
  "Non-nil when a preedit character is currently displayed in the terminal."
  (> (length +vterm--hangul-preedit-sent) 0))

(defun +vterm--hangul-active-p ()
  "Non-nil when hangul input is active and vterm terminal is live."
  (and vterm--term +vterm--hangul-active))

(defun +vterm--hangul-set-preedit (str)
  "Send STR to terminal as new preedit and update tracking state.
If STR is empty, clear tracking without sending."
  (if (> (length str) 0)
      (progn
        (vterm-send-string str)
        (setq +vterm--hangul-preedit-sent str))
    (setq +vterm--hangul-preedit-sent "")))

(defun +vterm--hangul-capture-self-insert (_n &optional char)
  "Capture self-insert-command output during per-keystroke hangul composition."
  (let ((c (or char (and (characterp last-command-event) last-command-event))))
    (when c
      (setq +vterm--hangul-captured
            (concat +vterm--hangul-captured (char-to-string c))))))

(defun +vterm--hangul-erase-preedit ()
  "Erase the inline preedit character from the vterm terminal."
  (when (+vterm--hangul-preedit-p)
    (vterm-send-string "\177")
    (setq +vterm--hangul-preedit-sent "")))

(defun +vterm--hangul-flush ()
  "Commit pending preedit: already inline in terminal, just clear tracking state."
  (when (+vterm--hangul-preedit-p)
    (setq +vterm--hangul-preedit-sent "")
    (setq hangul-queue (make-vector +vterm--hangul-queue-length 0))))

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
      (+vterm--hangul-set-preedit (if (> (length captured) 0) (substring captured -1) "")))))

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
    (+vterm--hangul-set-preedit +vterm--hangul-captured)))

(defun +vterm--self-insert-with-im (orig-fn)
  "Around advice for `vterm--self-insert' supporting Emacs hangul input.
Calls hangul2-input-method-internal per keystroke so each committed
syllable is sent to the terminal immediately."
  (if (and (+vterm--hangul-active-p)
           (characterp last-command-event)
           (not (memq 'meta (event-modifiers last-command-event)))
           (not (memq 'control (event-modifiers last-command-event))))
      (let ((key (event-basic-type last-command-event)))
        (cond
         ((hangul-alphabetp key)
          (+vterm--hangul-compose-key last-command-event))
         ((and (or (eq key 'backspace)
                   (and (integerp key) (or (= key ?\d) (= key ?\^H))))
               (+vterm--hangul-preedit-p))
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
  (if (+vterm--hangul-active-p)
      (if (+vterm--hangul-preedit-p)
          (+vterm--hangul-decompose-backspace)
        (funcall orig-fn))
    (funcall orig-fn)))

(defun +vterm--send-return-flush-im (orig-fn)
  "Around advice for `vterm-send-return' to flush pending hangul preedit.
The preedit char is already inline in the terminal and becomes committed text;
this clears tracking state before Enter is sent."
  (when (+vterm--hangul-active-p)
    (+vterm--hangul-flush))
  (funcall orig-fn))

(defun +vterm-toggle-korean ()
  "Toggle Korean hangul input method in vterm buffer."
  (interactive)
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
    (setq hangul-queue (make-vector +vterm--hangul-queue-length 0))
    (setq-local +vterm--hangul-active t)
    (setq-local current-input-method "korean-hangul")
    (setq-local input-method-function nil)
    (when (boundp 'evil-insert-state-entry-hook)
      (add-hook 'evil-insert-state-entry-hook
                #'+vterm--after-evil-insert-clear-imf t t))
    (force-mode-line-update)
    (message "Korean input: ON 한2")))

(defun vterm-hangul-setup ()
  "Install vterm hangul advice and keybindings."
  (advice-add 'vterm--self-insert   :around #'+vterm--self-insert-with-im)
  (advice-add 'vterm-send-backspace :around #'+vterm--send-backspace-with-im)
  (advice-add 'vterm-send-return    :around #'+vterm--send-return-flush-im)
  (dolist (key +vterm-hangul-toggle-keys)
    (add-to-list 'vterm-keymap-exceptions key)
    (define-key vterm-mode-map (kbd key) #'+vterm-toggle-korean)))

(provide 'vterm-hangul)
;;; vterm-hangul.el ends here