;;; module-util.el --- Summery  -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:

(require 'dash)
(require 's)
(require 'f)

(defun load-modules-with-list (module-path modules)
  "custom module load"
    (add-to-list 'load-path (expand-file-name module-path))
    (setq-local target
        (-map (lambda (module)
                (f-long
                    (f-join module-path (s-concat "+" (symbol-name module)))))
            modules)
        )
    (dolist
        (it target)
        (condition-case err
            (require (intern (f-filename it)))
          (error (message "Failed to load module %s: %s" it (error-message-string err))))))

(defun temp-buffer ()
    "open up a guaranteed new scratch buffer"
    (interactive)
    (switch-to-buffer (cl-loop for num from 0
                          for name = (format "temp-%03i" num)
                          while (get-buffer name)
                          finally return name)))

(provide 'module-util)
;;; module-util.el ends here
