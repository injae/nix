;;; +doc.el --- Summery -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(use-package eldoc :ensure nil
    :hook (emacs-startup . global-eldoc-mode)
    :preface
    (defvar eldoc-posframe-buffer "*eldoc-posframe-buffer*" "The posframe buffer name use by eldoc-posframe.")
    (defun my/posframe-top-right-corner (info)
        (let* ((parent-w (plist-get info :parent-frame-width))
                (parent-h (plist-get info :parent-frame-height))
                (pos-w    (plist-get info :posframe-width))
                (pos-h    (plist-get info :posframe-height))
                (xoff     (or (plist-get info :x-pixel-offset) 0))
                (yoff     (or (plist-get info :y-pixel-offset) 0))
                (final-x  (max 0 (- parent-w pos-w xoff)))
                (final-y  (max 0 yoff)))
            (cons final-x final-y)))

    (defun my/eldoc-posframe-show (str &rest args)
        (posframe-show
        eldoc-posframe-buffer
        :string (apply #'format str args)
        :parent-frame (selected-frame)
        :poshandler #'my/posframe-top-right-corner
        :x-pixel-offset 16
        :y-pixel-offset 16
        :max-width 100
        :max-height 30
        :left-fringe 8
        :right-fringe 8
        :internal-border-width 2
        :internal-border-color (face-attribute 'font-lock-comment-face :foreground nil t)
        :background-color (face-background 'tooltip nil t)))

    (defun my/eldoc-posframe-show-full (_str &rest _args)
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
                    :internal-border-color (face-attribute 'font-lock-comment-face :foreground nil t)
                    :background-color (face-background 'tooltip nil t))))))))
    :config
    (setq
        eldoc-message-function #'my/eldoc-posframe-show-full
        eldoc-echo-area-use-multiline-p t
        )
    ;; doom-modeline-mode가 eldoc-message-function 건드리는 걸 막기
    (define-advice doom-modeline-mode (:after (&rest _) restore-eldoc-posframe)
        "doom-modeline이 eldoc-message-function을 덮어쓴 뒤 다시 복원"
        (setq eldoc-message-function #'my/eldoc-posframe-show-full))
    )

(provide '+doc)
;;; +doc.el ends here
