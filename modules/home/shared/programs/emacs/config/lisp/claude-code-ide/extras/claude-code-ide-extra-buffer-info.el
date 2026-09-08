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
    :name "buffer-info"
    :description "Buffer name + major-mode. No arg: all visible buffers by recency. Pass name: single buffer."
     :args '((:name "buffer_name"
              :type string
              :optional t
              :description "Buffer name. Omit for all.")))

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
    :name "last-buffer"
    :description "Most recently used non-internal, non-claude buffer. Shows file user was editing."
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
                    (line (line-number-at-pos pos))
                    (sig  (save-excursion
                            (goto-char pos)
                            (string-trim
                             (buffer-substring-no-properties
                              (line-beginning-position)
                              (line-end-position))))))
          (push (cons line (format "%d: %s%s  %s" line prefix name sig)) pairs)))))
    pairs))

(defun claude-code-ide-mcp--file-outline-one (file-path)
  "Return the outline report for the single file FILE-PATH."
  (let ((inhibit-redisplay t))
    (claude-code-ide-mcp--with-temp-visit file-path
      (save-excursion
        ;; imenu caches its index; with `imenu-auto-rescan' nil it never
        ;; rebuilds, so an already-indexed buffer returns stale marker
        ;; positions.  Reset first to force a fresh build matching current text.
        (setq imenu--index-alist nil)
        (let* ((mode (symbol-name major-mode))
               (has-treesit (and (fboundp 'treesit-parser-list)
                                 (not (null (treesit-parser-list)))))
               (index (condition-case _ (imenu--make-index-alist t) (error nil)))
               (pairs (when index (claude-code-ide-mcp--imenu-collect index "")))
               (symbols (mapcar #'cdr (sort pairs (lambda (a b) (< (car a) (car b)))))))
          (concat
           (format "file: %s\nmajor-mode: %s\ntreesit: %s"
                   (expand-file-name file-path) mode
                   (cond (has-treesit "available")
                         (symbols "unavailable (imenu fallback)")
                         (t "unavailable")))
           (if symbols
               (concat "\n\nsymbols:\n" (string-join symbols "\n"))
             "")))))))

(defun claude-code-ide-mcp-file-outline (file-path)
  "Return major-mode, treesit availability, and symbol list for FILE-PATH.
FILE-PATH may be a comma-separated list of files, so a path containing a comma
cannot be passed here.  One unreadable file reports its own error and the rest
are still returned."
  (condition-case err
      (mapconcat
       (lambda (file)
         (condition-case one
             (claude-code-ide-mcp--file-outline-one file)
           (error (format "file: %s\nError: %s" file (error-message-string one)))))
       (split-string file-path "," t "[ \t\n]+")
       "\n\n")
    (error (format "Error: %s" (error-message-string err)))))

(claude-code-ide-make-tool
    :function #'claude-code-ide-mcp-file-outline
    :name "file-outline"
    :description "major-mode, treesit, and all symbols with line numbers and signatures. Reads in the background, then closes again any buffer the call itself opened. Takes several files as one comma-separated list, so a path containing a comma cannot be passed; one unreadable file reports its own error and the rest still come back. \"treesit: unavailable\" plus a symbol list means imenu supplied the symbols -- that outline is still usable."
    :args '((:name "file_path"
             :type string
             :description "Absolute path to file, or several comma-separated paths")))

(defun claude-code-ide-mcp-symbol-source (file-path line)
  "Return source code of the declaration at LINE in FILE-PATH.
Uses tree-sitter to find exact declaration bounds when available."
  (condition-case err
      (let ((inhibit-redisplay t))
        (claude-code-ide-mcp--with-temp-visit file-path
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
    :name "symbol-source"
    :description "Source of declaration at line (from file_outline) via tree-sitter. Falls back to 30-line read."
    :args '((:name "file_path"
             :type string
             :description "Absolute path to file")
            (:name "line"
             :type number
             :description "Target symbol line (1-based, from file-outline)")))

(provide 'claude-code-ide-extra-buffer-info)
;;; claude-code-ide-extra-buffer-info.el ends here
