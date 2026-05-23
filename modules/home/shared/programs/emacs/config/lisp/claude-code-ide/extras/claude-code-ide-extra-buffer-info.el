;;; claude-code-ide-extra-buffer-info.el --- MCP tools: buffer info and file outline -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(require 'claude-code-ide-mcp-server)

(defun claude-code-ide-mcp-buffer-info (&optional buffer-name)
  "Return name and major-mode for buffers.
If BUFFER-NAME is given, return info for that buffer only.
Otherwise return all user-visible buffers ordered by recency."
  (condition-case err
      (if (and buffer-name (not (string-empty-p buffer-name)))
          (let ((buf (get-buffer buffer-name)))
            (if buf
                (with-current-buffer buf
                  (format "buffer: %s\nmajor-mode: %s" (buffer-name) (symbol-name major-mode)))
              (format "Buffer '%s' not found." buffer-name)))
        (let ((bufs (seq-filter
                     (lambda (b)
                       (not (string-prefix-p " " (buffer-name b))))
                     (buffer-list))))
          (mapconcat
           (lambda (b)
             (with-current-buffer b
               (format "%s  [%s]" (buffer-name) (symbol-name major-mode))))
           bufs
           "\n")))
    (error (format "Error: %s" (error-message-string err)))))

(claude-code-ide-make-tool
    :function #'claude-code-ide-mcp-buffer-info
    :name "claude-code-ide-mcp-buffer-info"
    :description "Return buffer name and major-mode. With no argument, lists all user-visible buffers ordered by recency (most recently used first). Pass a buffer name to get info for that specific buffer only."
    :args '((:name "buffer_name"
             :type string
             :description "Optional buffer name. Omit to list all user-visible buffers.")))

(defun claude-code-ide-mcp-last-user-buffer ()
  "Return the most recently used buffer that is not internal or a claude-code buffer."
  (condition-case err
      (let ((buf (seq-find
                  (lambda (b)
                    (let ((name (buffer-name b)))
                      (and (not (string-prefix-p " " name))
                           (not (string-match-p "\\*claude-code" name)))))
                  (buffer-list))))
        (if buf
            (with-current-buffer buf
              (format "buffer: %s\nmajor-mode: %s" (buffer-name) (symbol-name major-mode)))
          "No user buffer found."))
    (error (format "Error: %s" (error-message-string err)))))

(claude-code-ide-make-tool
    :function #'claude-code-ide-mcp-last-user-buffer
    :name "claude-code-ide-mcp-last-user-buffer"
    :description "Return the most recently used buffer that is not an internal buffer or a claude-code buffer. Useful for identifying which file the user was last editing."
    :args '())

(defun claude-code-ide-mcp--imenu-collect (index prefix)
  "Return list of (LINE . STRING) pairs from imenu INDEX with PREFIX applied."
  (let (pairs)
    (dolist (item index)
      (cond
       ((equal (car item) "*Rescan*") nil)
       ((imenu--subalist-p item)
        (setq pairs
              (append pairs
                      (claude-code-ide-mcp--imenu-collect
                       (cdr item)
                       (format "[%s] " (substring-no-properties (car item)))))))
       (t
        (when-let* ((name (substring-no-properties (car item)))
                    (raw  (cdr item))
                    (pos  (cond ((overlayp raw) (overlay-start raw))
                                ((markerp raw)  (marker-position raw))
                                ((integerp raw) raw)))
                    (line (line-number-at-pos pos)))
          (push (cons line (format "%d: %s%s" line prefix name)) pairs)))))
    pairs))

(defun claude-code-ide-mcp-file-outline (file-path)
  "Return major-mode, treesit availability, and symbol list for FILE-PATH.
Opens the file in the background if not already open."
  (condition-case err
      (let ((inhibit-redisplay t))
        (with-current-buffer (or (find-buffer-visiting file-path)
                                 (find-file-noselect file-path))
          (save-excursion
            (let* ((mode (symbol-name major-mode))
                   (has-treesit (and (fboundp 'treesit-parser-list)
                                     (not (null (treesit-parser-list)))))
                   (index (condition-case _ (imenu--make-index-alist t) (error nil)))
                   (pairs (when index (claude-code-ide-mcp--imenu-collect index "")))
                   (symbols (mapcar #'cdr (sort pairs (lambda (a b) (< (car a) (car b)))))))
              (concat
               (format "buffer: %s\nmajor-mode: %s\ntreesit: %s"
                       (buffer-name) mode
                       (if has-treesit "available" "unavailable"))
               (if symbols
                   (concat "\n\nsymbols:\n" (string-join symbols "\n"))
                 ""))))))
    (error (format "Error: %s" (error-message-string err)))))

(claude-code-ide-make-tool
    :function #'claude-code-ide-mcp-file-outline
    :name "claude-code-ide-mcp-file-outline"
    :description "Return major-mode, treesit availability, and imenu symbol list for a file path in one call. Opens the file in the background if not already open. Replaces separate file-mode + imenu-list-symbols calls — use this as Step 1+2 of file analysis."
    :args '((:name "file_path"
             :type string
             :description "Absolute path to the file to inspect.")))

(defun claude-code-ide-mcp-symbol-source (file-path line)
  "Return source code of the declaration at LINE in FILE-PATH.
Uses tree-sitter to find exact declaration bounds when available."
  (condition-case err
      (let ((inhibit-redisplay t))
        (with-current-buffer (or (find-buffer-visiting file-path)
                                 (find-file-noselect file-path))
          (save-excursion
            (goto-char (point-min))
            (forward-line (1- line))
            (if (and (fboundp 'treesit-parser-list)
                     (treesit-parser-list)
                     (fboundp 'treesit-node-at)
                     (fboundp 'treesit-parent-until))
                (let* ((node (treesit-node-at (point)))
                       (decl (treesit-parent-until
                              node
                              (lambda (n)
                                (when-let ((parent (treesit-node-parent n)))
                                  (null (treesit-node-parent parent))))))
                       (start (if decl (treesit-node-start decl)
                                (line-beginning-position)))
                       (end   (if decl (treesit-node-end decl)
                                (line-end-position))))
                  (buffer-substring-no-properties start end))
              (buffer-substring-no-properties
               (line-beginning-position)
               (save-excursion (forward-line 30) (point)))))))
    (error (format "Error: %s" (error-message-string err)))))

(claude-code-ide-make-tool
    :function #'claude-code-ide-mcp-symbol-source
    :name "claude-code-ide-mcp-symbol-source"
    :description "Return the source code of the declaration at a given line using tree-sitter to find exact bounds. Takes a file path and line number (from file-outline). Replaces separate treesit-info + Read calls — use this as Step 3+4 of file analysis."
    :args '((:name "file_path"
             :type string
             :description "Absolute path to the file.")
            (:name "line"
             :type number
             :description "1-based line number of the target symbol (from file-outline).")))

(provide 'claude-code-ide-extra-buffer-info)
;;; claude-code-ide-extra-buffer-info.el ends here
