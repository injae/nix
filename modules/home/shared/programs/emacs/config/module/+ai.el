;;; +ai.el --- Summery -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(use-package websocket :demand t)
(use-package web-server :demand t)

(use-package claude-code-ide :ensure nil :load-path "~/.emacs.d/lisp/claude-code-ide/"
    :general (leader "a" '(claude-code-ide-menu :wk "AI CLI Menu"))
    :custom
    (claude-code-ide-open-in-new-frame t)
    (claude-code-ide-enable-mcp-server t)
    (claude-code-ide-terminal-backend 'vterm)
    (claude-code-ide-vterm-anti-flicker nil)
    (claude-code-ide-focus-claude-after-ediff nil)
    ;; (claude-code-ide-backend 'opencode)   ;; switch to opencode
    ;; (claude-code-ide-open-code-model "anthropic/claude-sonnet-4-20250514")
    :config
    (claude-code-ide-emacs-tools-setup)
    (require 'claude-code-ide-emacs-tools-extra))

(defun +ediff-setup-header ()
  "Show key hints in ediff control buffer header line."
  (when (and (boundp 'ediff-control-buffer) ediff-control-buffer)
    (with-current-buffer ediff-control-buffer
      (setq-local header-line-format
        (concat
         (propertize " n/p" 'face 'bold) ":다음/이전  "
         (propertize "a/b" 'face 'bold) ":A→B/B→A 복사  "
         (propertize "q" 'face '(:weight bold :foreground "red")) ":종료(수락/거부)  "
         (propertize "?" 'face 'bold) ":전체도움말")))))

(add-hook 'ediff-startup-hook #'+ediff-setup-header)

(provide '+ai)
;;; +ai.el ends here
