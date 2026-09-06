;;; claude-code-ide-extra-sync.el --- MCP tools: language server file sync -*- lexical-binding: t; -*-
;;; Commentary:
;; file-changed: tell Emacs and its language servers that a file changed on
;; disk.  An edit made outside Emacs can otherwise stay invisible to the
;; server indefinitely.  eglot sends `workspace/didChangeWatchedFiles' only
;; for files no buffer visits, so an open buffer blocks that route until it is
;; reverted; and once `eglot-max-file-watches' is reached, `eglot--watch-globs'
;; signals and unregisters the whole watch group, leaving a large project with
;; no change reporting at all.
;;; Code:

(require 'jsonrpc)
(require 'project)
(require 'claude-code-ide-mcp-server)

(declare-function eglot-path-to-uri "eglot" (path &rest args))
(defvar eglot--servers-by-project)

(defconst claude-code-ide-mcp--sync-change-types
  '(("created" . 1) ("changed" . 2) ("deleted" . 3))
  "LSP FileChangeType values by name.")

(defun claude-code-ide-mcp--sync-servers (path)
  "Return the eglot servers whose project root contains PATH."
  (when (and (boundp 'eglot--servers-by-project) eglot--servers-by-project)
    (let (servers)
      (maphash (lambda (project running)
                 (when-let* ((root (ignore-errors (project-root project))))
                   (when (string-prefix-p (expand-file-name root) path)
                     (setq servers (append servers running)))))
               eglot--servers-by-project)
      servers)))

(defun claude-code-ide-mcp--sync-notify (path type)
  "Announce PATH with FileChangeType TYPE to every server owning it."
  (let ((servers (claude-code-ide-mcp--sync-servers path)))
    (dolist (server servers)
      (jsonrpc-notify server :workspace/didChangeWatchedFiles
                      `(:changes ,(vector `(:uri ,(eglot-path-to-uri path)
                                                 :type ,type)))))
    (length servers)))

(defun claude-code-ide-mcp-file-changed (file &optional change)
  "Report that FILE changed on disk.
CHANGE is \"created\", \"changed\" (default) or \"deleted\".

A buffer visiting FILE is reverted, which makes eglot send
textDocument/didChange.  A file no buffer visits is announced to every
language server owning it.  A buffer holding unsaved changes is left alone
and reported: those edits outrank the file."
  (condition-case err
      (let* ((change (if (and change (not (string-empty-p change)))
                         change
                       "changed"))
             (type (or (cdr (assoc change claude-code-ide-mcp--sync-change-types))
                       (error "Unknown change type: %s" change)))
             (path (expand-file-name file))
             (buffer (find-buffer-visiting path)))
        (cond
         ;; A buffer cannot express deletion; only the server notification can.
         ((eq type 3)
          (format "Notified %d language server(s): deleted %s"
                  (claude-code-ide-mcp--sync-notify path type) path))
         ((and buffer (buffer-modified-p buffer))
          (format "Skipped %s: buffer has unsaved changes" path))
         (buffer
          (claude-code-ide-mcp--refresh-visiting path)
          (format "Reverted buffer: %s" path))
         (t
          (format "Notified %d language server(s): %s %s"
                  (claude-code-ide-mcp--sync-notify path type) change path))))
    (error (format "Error: %s" (error-message-string err)))))

(claude-code-ide-make-tool
    :function #'claude-code-ide-mcp-file-changed
    :name "file-changed"
    :description "Tell Emacs and its language servers that a file changed on disk, so a later lsp-def/lsp-refs/getDiagnostics call sees the edit instead of stale text. A buffer visiting the file is reverted (eglot then sends textDocument/didChange); a file no buffer visits is announced to every language server owning it via workspace/didChangeWatchedFiles. A buffer with unsaved changes is left alone and reported. Call it after editing a file through anything other than Emacs -- eglot suppresses its own watch notification while a buffer visits the file, and drops watches entirely once eglot-max-file-watches is reached, so neither route is guaranteed. Args: file (absolute path), change (optional: created | changed (default) | deleted)."
    :args '((:name "file"
             :type string
             :description "Absolute path of the file that changed")
            (:name "change"
             :type string
             :description "created | changed (default) | deleted")))

(provide 'claude-code-ide-extra-sync)
;;; claude-code-ide-extra-sync.el ends here
