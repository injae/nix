;;; +doc.el --- Summery -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(use-package eldoc :ensure nil
  :hook (emacs-startup . global-eldoc-mode))

(use-package eldoc-box
  :hook (eldoc-mode . eldoc-box-hover-mode)
  :custom
  (eldoc-box-max-pixel-width 600)
  (eldoc-box-max-pixel-height 400)
  (eldoc-box-clear-with-C-g t))


(provide '+doc)
;;; +doc.el ends here
