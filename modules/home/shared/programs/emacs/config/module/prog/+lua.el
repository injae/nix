;;; +lua.el --- Summery -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(use-package lua-mode
    :mode ("\\.lua\\'" . lua-mode)
    ;;:hook (lua-mode . (lambda ()
    ;;                       nix can not use, because of the lua-language-server cache path is nix store path
    ;;                      (setq lsp-clients-lua-language-server-install-dir
    ;;                          (f-join 
    ;;                                (s-trim-right (shell-command-to-string "nix eval nixpkgs#lua-language-server.outPath | tr -d '\"'"))
    ;;                                "share/lua-language-server"
    ;;                            )
    ;;                          )
    ;;                      (lsp-deferred)
    ;;                      ))
    )

(provide '+lua)
;;; +lua.el ends here
