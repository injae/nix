;;; +flutter.el --- Summery -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

;(use-package dart-mode
;:after lsp
;:mode   ("\\.dart\\'" . dart-mode)
;:custom (dart-format-on-save t)
;        (dart-enable-analysis-server t)
;        (dart-sdk-path (expand-file-name "~/dev/flutter/bin/cache/dart-sdk/"))
;:init (add-hook 'dart-mode-hook 'lsp)
;)
;
;(use-package flutter
;:after dart-mode
;:general (:keymaps 'dart-mode-map "C-M-x" 'flutter-run-or-hot-reload)
;:custom (flutter-sdk-path (expand-file-name "~/dev/flutter/"))
;)

(provide '+flutter)
;;; +flutter.el ends here
