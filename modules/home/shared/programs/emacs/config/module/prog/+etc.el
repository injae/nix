;;; +etc.el --- Summery
;;; -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(use-package protobuf-mode)

(use-package lua-mode
:mode ("\\.lua\\'" . lua-ts-mode)
:hook (lua-ts-mode . my/eglot-ensure)
)

(provide '+etc)
;;; +etc.el ends here
