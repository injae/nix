;;; +doc.el --- Summery -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(use-package eldoc :ensure nil
  :hook (emacs-startup . global-eldoc-mode)
  :preface
  (defvar eldoc-posframe-buffer "*eldoc-posframe-buffer*")
  (defvar-local my/eldoc-posframe-timer nil)

  (defun my/eldoc-posframe-hide ()
    (when (timerp my/eldoc-posframe-timer)
      (cancel-timer my/eldoc-posframe-timer)
      (setq my/eldoc-posframe-timer nil))
    (posframe-hide eldoc-posframe-buffer))

  (defun my/posframe-top-right-corner (info)
    (let* ((parent-w (plist-get info :parent-frame-width))
           (pos-w    (plist-get info :posframe-width))
           (xoff     (or (plist-get info :x-pixel-offset) 0))
           (yoff     (or (plist-get info :y-pixel-offset) 0)))
      (cons (max 0 (- parent-w pos-w xoff))
            (max 0 yoff))))

  (defun my/eldoc-posframe-show-full (_str &rest _args)
    (my/eldoc-posframe-hide)
    (setq my/eldoc-posframe-timer
          (run-with-idle-timer
           0.2 nil
           (lambda ()
             (let ((buf (ignore-errors (eldoc-doc-buffer))))
               (if (not (buffer-live-p buf))
                   (posframe-hide eldoc-posframe-buffer)
                 (with-current-buffer buf
                   (let ((text (string-trim
                                (buffer-substring-no-properties
                                 (point-min) (point-max)))))
                     (if (string-empty-p text)
                         (posframe-hide eldoc-posframe-buffer)
                       (posframe-show
                        eldoc-posframe-buffer
                        :string text
                        :parent-frame (selected-frame)
                        :poshandler #'my/posframe-top-right-corner
                        :x-pixel-offset 16
                        :y-pixel-offset 16
                        :max-width 100
                        :max-height 30
                        :left-fringe 8
                        :right-fringe 8
                        :internal-border-width 2
                        :internal-border-color
                        (face-attribute 'font-lock-comment-face :foreground nil t)
                        :background-color
                        (face-background 'tooltip nil t)))))))))))

  (defun my/eldoc-posframe-setup-buffer ()
    (add-hook 'pre-command-hook #'my/eldoc-posframe-hide nil t)
    (add-hook 'focus-out-hook #'my/eldoc-posframe-hide nil t))

  :config
  (setq eldoc-message-function #'my/eldoc-posframe-show-full
        eldoc-echo-area-use-multiline-p t)

  (add-hook 'eldoc-mode-hook #'my/eldoc-posframe-setup-buffer)

  (define-advice doom-modeline-mode (:after (&rest _) restore-eldoc-posframe)
      (setq eldoc-message-function #'my/eldoc-posframe-show-full))
  )


(provide '+doc)
;;; +doc.el ends here
