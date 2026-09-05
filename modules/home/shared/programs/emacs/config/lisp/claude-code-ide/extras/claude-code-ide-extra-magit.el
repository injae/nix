;;; claude-code-ide-extra-magit.el --- MCP tools: magit git operations -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(require 'claude-code-ide-mcp-server)

(defvar with-editor-emacsclient-executable)

(defun claude-code-ide-mcp--magit-repo (repo-dir)
  "Return the git toplevel to operate on.
REPO-DIR overrides the calling session's project directory.  Never
falls back to the current buffer, which may belong to another repo."
  (require 'magit nil 'noerror)
  (let* ((session-dir (plist-get (claude-code-ide-mcp-server-get-session-context)
                                 :project-dir))
         (dir (cond
               ((and (stringp repo-dir) (not (string-empty-p repo-dir)))
                ;; Relative paths resolve against the session, never against
                ;; the focused buffer's `default-directory'.
                (cond ((file-name-absolute-p repo-dir) (expand-file-name repo-dir))
                      (session-dir (expand-file-name repo-dir session-dir))
                      (t (error "Relative project_dir without a session project: %s"
                                repo-dir))))
               (session-dir)
               (t (error "No session project directory; pass project_dir")))))
    (or (magit-toplevel dir)
        (error "Not inside a git repository: %s" dir))))

(defun claude-code-ide-mcp--magit-git (&rest args)
  "Run git with ARGS synchronously in `default-directory', then refresh magit.
Signal an error on non-zero exit; `magit-run-git' would report success."
  (let ((exit (apply #'magit-call-git args)))
    (magit-refresh)
    (unless (eq exit 0)
      (error "git %s failed (exit %s); see %s"
             (car args) exit (buffer-name (magit-process-buffer t))))))

(defconst claude-code-ide-mcp--magit-repo-arg
  '(:name "project_dir"
    :type string
    :optional t
    :description "Repository to act on. Defaults to the calling session's project; pass only to target another repo.")
  "MCP argument spec for the optional repository override.")

(defun claude-code-ide-mcp-magit-stage (file-path &optional repo-dir)
  "Stage FILE-PATH with git add.
REPO-DIR overrides the calling session's repository."
  (condition-case err
      (let ((default-directory (claude-code-ide-mcp--magit-repo repo-dir)))
        (claude-code-ide-mcp--magit-git "add" "--" file-path)
        (format "Staged: %s (in %s)" file-path default-directory))
    (error (format "Error: %s" (error-message-string err)))))

(claude-code-ide-make-tool
    :function #'claude-code-ide-mcp-magit-stage
    :name "git-stage"
    :description "Stage file via git add. Refreshes open magit buffers."
    :args `((:name "file_path"
             :type string
             :description "Relative or absolute path")
            ,claude-code-ide-mcp--magit-repo-arg))

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
      ;; git-commit-setup resets the modified flag right after this hook.
      (write-region (point-min) (point-max) buffer-file-name nil 'silent))))

(add-hook 'git-commit-setup-hook #'claude-code-ide--git-commit-insert-pending)

(defun claude-code-ide-mcp-magit-prepare-commit (message &optional repo-dir)
  "Open a magit commit buffer pre-filled with MESSAGE; do not commit.
REPO-DIR overrides the calling session's repository."
  (condition-case err
      (let* ((default-directory (claude-code-ide-mcp--magit-repo repo-dir))
             (repo default-directory)
             ;; git inherits the Claude vterm pty; emacsclient cannot open a
             ;; frame there, so let with-editor use its sleeping-editor.
             (with-editor-emacsclient-executable nil)
             (magit-win (seq-find
                         (lambda (w)
                           (let ((buf (window-buffer w)))
                             (and (string-prefix-p "magit:" (buffer-name buf))
                                  (with-current-buffer buf
                                    (equal (magit-toplevel) repo)))))
                         (window-list))))
        (setq claude-code-ide--pending-commit-message message)
        ;; The hook consumes the message only once the commit buffer opens;
        ;; if git never gets that far, drop it so it cannot leak into an
        ;; unrelated commit buffer later.
        (condition-case err
            (if magit-win
                (with-selected-window magit-win (magit-commit-create))
              (magit-commit-create))
          (error
           (setq claude-code-ide--pending-commit-message nil)
           (signal (car err) (cdr err))))
        (format "Commit buffer ready for %s — review the message and press C-c C-c to commit." repo))
    (error (format "Error: %s" (error-message-string err)))))

(claude-code-ide-make-tool
    :function #'claude-code-ide-mcp-magit-prepare-commit
    :name "git-prepare-commit"
    :description "Open magit commit buffer, pre-fill message. Does NOT commit. User presses C-c C-c."
    :args `((:name "message"
             :type string
             :description "Commit message to pre-fill")
            ,claude-code-ide-mcp--magit-repo-arg))

(defun claude-code-ide-mcp-magit-commit (message &optional repo-dir)
  "Commit staged changes with MESSAGE immediately.
REPO-DIR overrides the calling session's repository."
  (condition-case err
      (let ((default-directory (claude-code-ide-mcp--magit-repo repo-dir)))
        (claude-code-ide-mcp--magit-git "commit" "-m" message)
        (format "Committed in %s: %s"
                default-directory
                (substring message 0 (min 60 (length message)))))
    (error (format "Error: %s" (error-message-string err)))))

(claude-code-ide-make-tool
    :function #'claude-code-ide-mcp-magit-commit
    :name "git-commit"
    :description "Commit staged changes immediately. Use git-prepare-commit if user should review first."
    :args `((:name "message"
             :type string
             :description "Commit message")
            ,claude-code-ide-mcp--magit-repo-arg))

(defun claude-code-ide-mcp-magit-amend (&optional message repo-dir)
  "Amend HEAD with the staged changes.
MESSAGE replaces the commit message; without it the message is kept.
REPO-DIR overrides the calling session's repository."
  (condition-case err
      (let ((default-directory (claude-code-ide-mcp--magit-repo repo-dir)))
        (if (and (stringp message) (not (string-empty-p message)))
            (claude-code-ide-mcp--magit-git "commit" "--amend" "-m" message)
          (claude-code-ide-mcp--magit-git "commit" "--amend" "--no-edit"))
        (format "Amended in %s: %s"
                default-directory
                (magit-git-string "log" "-1" "--format=%h %s")))
    (error (format "Error: %s" (error-message-string err)))))

(claude-code-ide-make-tool
    :function #'claude-code-ide-mcp-magit-amend
    :name "git-amend"
    :description "Amend HEAD with staged changes. Keeps the message unless a new one is given."
    :args `((:name "message"
             :type string
             :optional t
             :description "New commit message. Omit to keep the current one.")
            ,claude-code-ide-mcp--magit-repo-arg))

(provide 'claude-code-ide-extra-magit)
;;; claude-code-ide-extra-magit.el ends here
