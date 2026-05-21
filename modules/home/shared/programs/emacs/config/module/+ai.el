;;; +ai.el --- Summery -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(use-package claude-code-ide :ensure (:repo "manzaltu/claude-code-ide.el" :host github)
    :general (leader "a" '(claude-code-ide-menu :wk "Claude Code IDE Menu"))
    :custom
    (claude-code-ide-open-in-new-frame t)
    (claude-code-ide-enable-mcp-server t)
    (claude-code-ide-terminal-backend 'vterm)
    (claude-code-ide-vterm-anti-flicker nil)
    (claude-code-ide-focus-claude-after-ediff nil)
    :config
    (claude-code-ide-emacs-tools-setup)
    (load-modules-with-list
        (f-join user-emacs-module-directory "mcp")
        '(describe-symbol find-references callees lsp-navigation call-function buffer-info formatting navigation magit elisp)))

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

(defun +claude-open-file-avoid-claude-window (orig-fn arguments)
  "Claude MCP openFile 호출 시 Claude 터미널 창 대신 다른 창에 파일을 연다."
  (let* ((cur-buf (window-buffer (selected-window)))
         (in-claude-win (string-match-p "^\\*claude-code\\["
                                        (buffer-name cur-buf)))
         (target-win (when in-claude-win
                       (seq-find
                        (lambda (w)
                          (not (string-match-p "^\\*claude-code\\["
                                               (buffer-name (window-buffer w)))))
                        (window-list nil 'no-mini)))))
    (if target-win
        (with-selected-window target-win
          (funcall orig-fn arguments))
      (funcall orig-fn arguments))))

(advice-add 'claude-code-ide-mcp-handle-open-file :around
            #'+claude-open-file-avoid-claude-window)

(provide '+ai)
;;; +ai.el ends here
