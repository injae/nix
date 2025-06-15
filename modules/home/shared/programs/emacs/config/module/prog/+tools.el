;;; +tools.el --- Summery -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

; brew install rust base system command
(use-package rust-system-command :ensure nil :no-require t :disabled
:ensure-system-package ((rg    . "cargo install ripgrep")
                        (exa   . "cargo install exa")
                        (bat   . "cargo install bat")
                        (procs . "cargo install procs")
                        (dust  . "cargo install du-dust")
                        (mcfly . "cargo install mcfly")
                        (erd   . "cargo install erdtree")
                        (cargo-install-update . "cargo install cargo-update"))
)

(provide '+tools)
;;; +tools.el ends here
