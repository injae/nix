;;; +copilot.el --- Summery -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(use-package copilot :ensure (:host github :repo "zerolfx/copilot.el" :files ("dist" "*.el"))
    :preface
    (defun copilot-disable-warning ()
        (setq-local copilot--indent-warning-printed-p t))
    (defun copilot-complete-or-accept ()
        "Command that either triggers a completion or accepts one if one
        is available."
        (interactive)
        (if (copilot--overlay-visible)
            (progn (copilot-accept-completion))
            (copilot-complete)))
    :hook ((prog-mode . copilot-mode)
           (text-mode . copilot-mode)
           (copilot-mode . copilot-disable-warning))
    ;; :custom (copilot--indent-warning-printed-p t)
    :custom (copilot-max-char -1) ;; disable the max char limit
    :bind (:map copilot-mode-map
                ;; ("<tab>" . my/copilot-tab)
                ;; ("C-<return>" . my/copilot-tab)
                ;; ("<tab>" . my/copilot-tab)
                ("C-<return>" . copilot-complete-or-accept)
                ("<right>"    . copilot-complete-or-accept)
                ("C-n" . copilot-next)
                ("C-p" . copilot-previous)
                ("C-g" . copilot-clear-overlay)
              )
    )



;; you can utilize :map :hook and :config to customize copilot
(provide '+copilot)
;;; +copilot.el ends here
