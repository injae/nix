;;; +third-party.el --- Emacs Configuration -*- lexical-binding: t -*-
;;; Commentary:
;; This config start here
;;; Code:

(use-package simple-httpd :disabled
    :ensure (:main "emacs-web-server/simple-httpd.el") ;; :host github :repo "skeeto/emacs-web-server"
    )

(use-package smudge :after exec-path-from-shell :disabled
:commands (smudge-controller-next-track smudge-controller-previous-track)
:general (leader "sn" 'smudge-controller-next-track
                 "sp" 'smudge-controller-previous-track
                 "ss" 'smudge-controller-toggle-play)
:config
    (exec-path-from-shell-getenvs '("SPOTIFY_ID" "SPOTIFY_SECRET"))
    (setq smudge-spotify-client-id     (getenv "SPOTIFY_ID"))
    (setq smudge-spotify-client-secret (getenv "SPOTIFY_SECRET"))
    (setq smudge-transport 'connect)
)
;; 
;; (use-package slack
;; :commands (slack-start)
;; :custom (slack-buffer-emojify t)
;;         (slack-prefer-current-team t)
;; :config (setq request-backend 'curl)
;; )
;; 
;; (use-package elcord
;;     :functions elcord-mode
;;     :custom (elcord-client-id "")
;;             (elcord-display-buffer-details nil)
;;             (elcord-quiet t)
;;     :config (elcord-mode)
;;     )
;; 
;; (use-package gptai
;;     :custom
;;     (gptai-model "text-davinci-003")
;;     (gptai-username "이인재")
;;     (gptai-api-key "")
;;     )

(provide '+third-party)
;;; +third-party.el ends here
