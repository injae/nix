;;; +org.el --- Summery  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(use-package org
:mode ("\\.org\\'" . org-mode)
:general (leader "oa" 'org-agenda
                 "ob" 'org-iswitchb
                 "oc" 'org-capture
                 "oe" 'org-edit-src-code
                 "ok" 'org-edit-src-exit
                 "ol" 'org-store-link)
;:init   (setq org-directory          (expand-file-name     "~/Dropbox/org   "))
;        (setq org-default-notes-file (concat org-directory "/notes/notes.org"))
:config (setq org-startup-indented   nil)
)

(use-package org-superstar :after org
:hook (org-mode . org-superstar-mode)
:custom (org-superstar-special-todo-items t)
;:custom-face
;    (org-level-1 ((t (:inherit outline-1 :height 1.3))))
;    (org-level-2 ((t (:inherit outline-2 :height 1.2))))
;    (org-level-3 ((t (:inherit outline-3 :height 1.1))))
;    (org-level-4 ((t (:inherit outline-4 :height 1.0))))
;    (org-level-5 ((t (:inherit outline-5 :height 1.0))))
)

(use-package valign :after org
    :hook (org-mode . valign-mode))

(use-package orgtbl-aggregate :after org)

(use-package toc-org :after org
    :hook (org-mode . toc-org-mode))

(use-package org-babel :ensure nil :no-require t :after org
:config (org-babel-do-load-languages
            'org-babel-load-languages
            '((emacs-lisp . t)
              (python     . t)
              (org        . t)
              (shell      . t)
              (C          . t)))
)

;(use-package org-roam  :disabled
;:custom  (org-roam-dailies-directory "journals/")
;:general (leader "of" '(org-roam-node-find :wk "Note"))
;:custom  (org-roam-directory (expand-file-name "~/GDrive/Roam/"))
;:config
;    (setq org-roam-dailies-capture-templates
;        '(("d" "default" entry "* %?"
;            :if-new (file+head "%<%Y-%m-%d>.org"
;                               "#+title: %<%Y-%m-%d>\n"))))
;    (setq org-roam-node-display-template (concat "${title:*} " (propertize "${tags:10}" 'face 'org-tag)))
;    (org-roam-db-autosync-enable)
;    (require 'org-roam-protocol) ;; If using org-roam-protocol
;    ;(org-roam-setup)
;)
;
;(use-package websocket  :after org-roam)
;
;(use-package org-roam-ui
;:after org-roam
;:config (setq org-roam-ui-sync-theme t)
;        (setq org-roam-ui-follow t)
;        (setq org-roam-ui-update-on-save t)
;        (setq org-roam-ui-open-on-start t)
;)

;(use-package org-journal  :disabled
;:after org
;:preface
;    (defun org-journal-find-location ()
;        (org-journal-new-entry t)
;        (goto-char (point-min)))
;:config
;    (setq org-journal-dir (expand-file-name "~/Dropbox/org/journal")
;            org-journal-file-format "%Y-%m-%d.org"
;            org-journal-date-format "%Y-%m-%d (%A)")
;    (add-to-list 'org-agenda-files (expand-file-name "~/Dropbox/org/journal"))
;    (setq org-journal-enable-agenda-integration t
;            org-icalendar-store-UID t
;            org-icalendar-include0tidi "all"
;            org-icalendar-conbined-agenda-file "~/calendar/org-journal.ics")
;    (org-journal-update-org-agenda-files)
;    (org-icalendar-combine-agenda-files)
;)
;
;(use-package org-capture :ensure nil :disabled
;:after org
;:config (setq org-reverse-note-order t)
;    (add-to-list 'org-agenda-files (expand-file-name "~/Dropbox/org/notes"))
;    (setq org-capture-templates
;        '(("t" "Todo" entry (file+headline "~/Dropbox/org/notes/notes.org" "Todos")
;            "* TODO %?\nAdded: %U\n" :prepend t :kill-buffer t)
;            ("l" "Link" entry (file+headline "~/Dropbox/org/notes/notes.org" "Links")
;            "* TODO %?\nAdded: %U\n" :prepend t :kill-buffer t)
;            ("j" "Journal" entry (function org-journal-find-location)
;            "* %(format-time-string org-journal-time-format)%^{Title}\n%i%?")
;            ("a" "Appointment" entry (file "~/Dropbox/org/agenda/gcal.org")
;            "* %?\n\n%^T\n\n:PROPERTIES:\n\n:END:\n\n")
;            )
;    )
;)
;
;(use-package org-agenda :ensure nil :disabled
;:after org
;:config (use-package evil-org  
;        :after (org evil)
;        :init (add-hook 'org-mode-hook 'evil-org-mode)
;            (add-hook 'evil-org-mode-hook (lambda () (evil-org-set-key-theme)))
;            (setq org-agenda-files '("~/.emacs.d/private/schedule.org"))
;            (require 'evil-org-agenda)
;            (evil-org-agenda-set-keys)
;        )
;)
;
;(use-package org-pomodoro  
;:after org-agenda
;:custom
;    (org-pomodoro-ask-upon-killing t)
;    (org-pomodoro-format "%s")
;    (org-pomodoro-short-break-format "%s")
;    (org-pomodoro-long-break-format  "%s")
;:custom-face
;    (org-pomodoro-mode-line         ((t (:foreground "#ff5555"))))
;    (org-pomodoro-mode-line-break   ((t (:foreground "#50fa7b"))))
;:hook
;    (org-pomodoro-started  . (lambda () (notifications-notify
;        :title "org-pomodoro"
;        :body "Let's focus for 25 minutes!"
;        :app-icon "~/.emacs.d/img/001-food-and-restaurant.png")))
;    (org-pomodoro-finished . (lambda () (notifications-notify
;        :title "org-pomodoro"
;        :body "Well done! Take a break."
;        :app-icon "~/.emacs.d/img/004-beer.png")))
;:general (:keymaps 'org-agenda-mode-map "p"  'org-pomodoro)
;)

;(use-package calfw  :disabled
;:commands cfw:open-calendar-buffer
;:config (use-package calfw-org :config (setq cfw:org-agenda-schedule-args '(:deadline :timestamp :sexp)))
;)
;
;(use-package calfw-gcal   :disabled
;:init (require 'calfw-gcal))
;
;(use-package ob-restclient  
;:after  (org restclient)
;:config (org-babel-do-load-languages 'org-babel-load-languages '((restclient . t)))
;)

(provide '+org)
;;; +org.el ends here
