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

(provide '+ai)
;;; +ai.el ends here
