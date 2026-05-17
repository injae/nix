;;; +git.el --- Summery -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(use-package rust-mode :after exec-path-from-shell
:mode ("\\.rs\\'" . rust-ts-mode)
:hook (rust-ts-mode . my/eglot-ensure)
:general (leader "hrf" 'rust-format-buffer)
)

(use-package cargo
:hook (rust-ts-mode . cargo-minor-mode)
:general (leader "hrb" 'cargo-process-build
                 "hrr" 'cargo-process-run
                 "hrt" 'cargo-process-test)
)


(provide '+rust)
;;; +rust.el ends here
