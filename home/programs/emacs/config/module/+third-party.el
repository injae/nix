;;; +third-party.el --- Emacs Configuration -*- lexical-binding: t -*-
;;; Commentary:
;; This config start here
;;; Code:

(use-package simple-httpd :disabled
    :ensure (:host github :repo "skeeto/emacs-web-server"
             :main "simple-httpd.el")
    )

(use-package smudge :after (exec-path-from-shell) :disabled
:commands (smudge-controller-next-track smudge-controller-previous-track)
:general (leader "sn" 'smudge-controller-next-track
                 "sp" 'smudge-controller-previous-track
                 "ss" 'smudge-controller-toggle-play)
:config
    (exec-path-from-shell-copy-envs '("SPOTIFY_ID" "SPOTIFY_SECRET"))
    (setq smudge-spotify-client-id     (getenv "SPOTIFY_ID"))
    (setq smudge-spotify-client-secret (getenv "SPOTIFY_SECRET"))
    (setq smudge-transport 'connect)
)

(use-package elcord :after exec-path-from-shell
    :custom (elcord-display-buffer-details nil)
            (elcord-quiet t)
    :config
    (exec-path-from-shell-copy-envs '("DISCORD_TOKEN"))
    (setq elcord-client-id (getenv "DISCORD_TOKEN"))
    (elcord-mode)
    )
;; 
(use-package gptai :after exec-path-from-shell
    :custom
    (gptai-model "text-davinci-003")
    (gptai-username "이인재")
    :config
    (exec-path-from-shell-copy-envs '("CHATGPT_API_KEY"))
    (setq gptai-api-key (getenv "CHATGPT_API_KEY"))
    )

(provide '+third-party)
;;; +third-party.el ends here
