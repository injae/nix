;;; +magit.el --- MCP tools: magit git operations -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(defun claude-code-ide-mcp-magit-stage (file-path)
  "Stage FILE-PATH using git add via magit. Refreshes open magit buffers."
  (condition-case err
      (let ((default-directory (or (magit-toplevel) default-directory)))
        (magit-run-git "add" "--" file-path)
        (format "Staged: %s" file-path))
    (error (format "Error: %s" (error-message-string err)))))

(claude-code-ide-make-tool
    :function #'claude-code-ide-mcp-magit-stage
    :name "claude-code-ide-mcp-magit-stage"
    :description "Stage a file for the next commit using git add. Refreshes any open magit buffers."
    :args '((:name "file_path"
             :type string
             :description "Relative or absolute path to the file to stage")))

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
      (insert msg "\n\n"))))

(add-hook 'git-commit-setup-hook #'claude-code-ide--git-commit-insert-pending)

(defun claude-code-ide-mcp-magit-prepare-commit (message)
  "Open magit commit buffer and pre-fill MESSAGE. Does not finish the commit.
The user reviews the message and presses C-c C-c to commit manually."
  (condition-case err
      (progn
        (setq claude-code-ide--pending-commit-message message)
        (let ((magit-win (seq-find
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
    :name "claude-code-ide-mcp-magit-prepare-commit"
    :description "Open the magit commit buffer and pre-fill the commit message. Does NOT finish the commit — the user reviews and presses C-c C-c manually."
    :args '((:name "message"
             :type string
             :description "The commit message to pre-fill")))

(defun claude-code-ide-mcp-magit-commit (message)
  "Create a git commit with MESSAGE from currently staged changes immediately."
  (condition-case err
      (let ((default-directory (or (magit-toplevel) default-directory)))
        (magit-run-git "commit" "-m" message)
        (format "Committed: %s" (substring message 0 (min 60 (length message)))))
    (error (format "Error: %s" (error-message-string err)))))

(claude-code-ide-make-tool
    :function #'claude-code-ide-mcp-magit-commit
    :name "claude-code-ide-mcp-magit-commit"
    :description "Create a git commit immediately with the given message from all staged changes. Use magit-prepare-commit instead if the user should review the message first."
    :args '((:name "message"
             :type string
             :description "The commit message")))

(provide '+magit)
;;; +magit.el ends here
