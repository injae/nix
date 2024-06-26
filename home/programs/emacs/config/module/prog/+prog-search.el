;;; +prog-search.el --- Summery
;;; -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(use-package dumb-jump
:after  company
:custom (dumb-jump-force-searcher 'rg)
        (dumb-jump-default-project "~/build")
:general (leader "hd"  '(:wk "Definition Jump")
                 "hdo" 'find-file-other-window
                 "hdj" 'xref-pop-marker-stack)
:init (add-hook 'xref-backend-functions #'dumb-jump-xref-activate)
)


(provide '+prog-search)
;;; +prog-search.el ends here
