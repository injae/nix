;;; +ai.el --- Summery -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(use-package gptel :after markdown-mode
  :config
    (setq
        gptel-model 'mistral:latest
        gptel-backend (gptel-make-ollama "Ollama"
                        :host "localhost:11434"
                        :stream t
                        :models '(codellama:34b mistral:latest)
                        )
        gptel-use-curl nil
      )
  )

(use-package smerge-mode :ensure nil :hook (prog-mode . smerge-mode))

(use-package elysium :after (gptel smerge-mode)
    :custom
    (elysium-window-size 0.33) ; The elysium buffer will be 1/3 your screen
    (elysium-window-style 'vertical) ; Can be customized to horizontal
    )

(use-package browser-hist :after embark
    :config (setq browser-hist-default-browser 'chrome)
    )

(use-package mcp :after gptel
  :custom (mcp-hub-servers
            `(("filesystem"
                . (:command "npx"
                   :args    ("-y" "@modelcontextprotocol/server-filesystem" "~/")))
              ("fetch"
                . (:command "uvx" :args ("mcp-server-fetch")))
              ("nixos"
                . (:command "uvx" :args ("mcp-nixos")))
             ))
  :config (require 'mcp-hub)
  :hook (after-init . mcp-hub-start-all-server))


(provide '+ai)
;;; +ai.el ends here
