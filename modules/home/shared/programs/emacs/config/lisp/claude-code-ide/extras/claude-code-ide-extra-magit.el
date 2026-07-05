;;; claude-code-ide-extra-magit.el --- MCP tools: magit git operations -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(require 'claude-code-ide-mcp-server)

(defun claude-code-ide-mcp-magit-stage (file-path)
  "Stage FILE-PATH using git add via magit."
  (condition-case err
      (let ((default-directory (or (ignore-errors (require 'magit nil 'noerror) (magit-toplevel)) default-directory)))
        (magit-run-git "add" "--" file-path)
        (format "Staged: %s" file-path))
    (error (format "Error: %s" (error-message-string err)))))

(claude-code-ide-make-tool
    :function #'claude-code-ide-mcp-magit-stage
    :name "git-stage"
    :description "Stage file via git add. Refreshes open magit buffers."
    :args '((:name "file_path"
             :type string
             :description "Relative or absolute path")))

(defvar claude-code-ide--pending-commit-message nil
  "Commit message to insert when the next git-commit buffer opens.")

(defun claude-code-ide--git-commit-insert-pending ()
  "Insert pending commit message into the current git-commit buffer."
  (when claude-code-ide--pending-commit-message
    (let ((msg claude-code-ide--pending-commit-message))
      (setq claude-code-ide--pending-commit-message nil)
      (goto-char (point-min))
      (let ((end (or (save-excursion
                       (when (re-search-forward "^#" nil t)
                         (line-beginning-position)))
                     (point-max))))
        (delete-region (point-min) end))
      (goto-char (point-min))
      (insert msg "\n\n")
      ;; git-commit-setup resets modified state immediately after this hook,
      ;; so write directly to avoid the buffer being treated as unmodified.
      (write-region (point-min) (point-max) buffer-file-name nil 'silent))))

(add-hook 'git-commit-setup-hook #'claude-code-ide--git-commit-insert-pending)

(defun claude-code-ide-mcp-magit-prepare-commit (message)
  "Open magit commit buffer and pre-fill MESSAGE without finishing the commit."
  (condition-case err
      (progn
        (require 'magit nil 'noerror)
        (setq claude-code-ide--pending-commit-message message)
        ;; MCP로 커밋을 띄우면 git이 Claude vterm의 pty(TERM=dumb)를 제어터미널로
        ;; 물려받아, with-editor의 emacsclient가 그 tty에 프레임을 만들려다
        ;; "Unknown terminal type"으로 실패한다.  emacsclient를 비활성화하면
        ;; with-editor가 터미널을 쓰지 않는 sleeping-editor(순수 sh)를 사용해
        ;; 기존 GUI 프레임에 커밋 버퍼를 연다.  이 커밋 프로세스에만 적용되며
        ;; (async 프로세스의 env는 시작 시점에 고정), 전역 emacsclient 설정은
        ;; Emacs 셸에서의 git commit용으로 보존된다.
        (let ((with-editor-emacsclient-executable nil)
              (magit-win (seq-find
                          (lambda (w)
                            (string-prefix-p "magit:" (buffer-name (window-buffer w))))
                          (window-list))))
          (if magit-win
              (with-selected-window magit-win (magit-commit-create))
            (magit-commit-create)))
        "Commit buffer ready — review the message and press C-c C-c to commit.")
    (error (format "Error: %s" (error-message-string err)))))

(claude-code-ide-make-tool
    :function #'claude-code-ide-mcp-magit-prepare-commit
    :name "git-prepare-commit"
    :description "Open magit commit buffer, pre-fill message. Does NOT commit. User presses C-c C-c."
    :args '((:name "message"
             :type string
             :description "Commit message to pre-fill")))

(defun claude-code-ide-mcp-magit-commit (message)
  "Create a git commit with MESSAGE from currently staged changes immediately."
  (condition-case err
      (let ((default-directory (or (ignore-errors (require 'magit nil 'noerror) (magit-toplevel)) default-directory)))
        (magit-run-git "commit" "-m" message)
        (format "Committed: %s" (substring message 0 (min 60 (length message)))))
    (error (format "Error: %s" (error-message-string err)))))

(claude-code-ide-make-tool
    :function #'claude-code-ide-mcp-magit-commit
    :name "git-commit"
    :description "Commit staged changes immediately. Use git-prepare-commit if user should review first."
    :args '((:name "message"
             :type string
             :description "Commit message")))

(provide 'claude-code-ide-extra-magit)
;;; claude-code-ide-extra-magit.el ends here
