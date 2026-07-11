;;; claude-code-ide-extra-search.el --- MCP tools: structural search -*- lexical-binding: t; -*-
;;; Commentary:
;; grep-block: ripgrep search whose hits expand to the enclosing tree-sitter
;; block, reporting the top-level declaration's range.
;;; Code:

(require 'claude-code-ide-mcp-server)
(require 'project)

(defun claude-code-ide-mcp--grep-block-root (path)
  "Return search root: PATH if non-empty, else project root or `default-directory'."
  (cond
   ((and path (not (string-empty-p path))) (expand-file-name path))
   ((project-current) (project-root (project-current)))
   (t (expand-file-name default-directory))))

(defun claude-code-ide-mcp--grep-block-search (pattern path)
  "Run rg for PATTERN under PATH.  Return list of (FILE . LINE) match cells."
  (let* ((root (claude-code-ide-mcp--grep-block-root path))
         (out (with-output-to-string
                (with-current-buffer standard-output
                  (call-process "rg" nil t nil "--vimgrep" "--" pattern root))))
         (matches '()))
    (dolist (ln (split-string out "\n" t))
      (when (string-match "\\`\\(.*?\\):\\([0-9]+\\):[0-9]+:" ln)
        (push (cons (match-string 1 ln)
                    (string-to-number (match-string 2 ln)))
              matches)))
    (nreverse matches)))

(defun claude-code-ide-mcp--grep-block-first-line (pos)
  "Return trimmed text of the line containing POS in the current buffer."
  (save-excursion
    (goto-char pos)
    (string-trim (buffer-substring-no-properties
                  (line-beginning-position) (line-end-position)))))

(defun claude-code-ide-mcp--grep-block-window (line)
  "Return a ±6-line window plist around LINE (tree-sitter fallback)."
  (let* ((max-line (line-number-at-pos (point-max)))
         (start (max 1 (- line 6)))
         (end (min max-line (+ line 6))))
    (save-excursion
      (goto-char (point-min)) (forward-line (1- start))
      (let ((bs (point)))
        (goto-char (point-min)) (forward-line (1- end))
        (let ((be (line-end-position)))
          (list :a-start nil :a-end nil :a-sig nil
                :b-type nil
                :b-start start :b-end end
                :b-source (buffer-substring-no-properties bs be)))))))

(defun claude-code-ide-mcp--grep-block-extract (line)
  "Return a block plist for the match at LINE in the current buffer.
Keys: :a-start :a-end :a-sig :b-start :b-end :b-source.
A = enclosing top-level declaration (range/signature only).
B = tightest enclosing named multi-line node (source).
Falls back to a line window when tree-sitter is unavailable."
  (save-excursion
    (goto-char (point-min))
    (forward-line (1- line))
    (back-to-indentation)
    (if (and (fboundp 'treesit-parser-list) (treesit-parser-list)
             (fboundp 'treesit-node-at))
        (let* ((node (treesit-node-at (point)))
               (a (and node
                       (treesit-parent-until
                        node
                        (lambda (n)
                          (when-let ((p (treesit-node-parent n)))
                            (null (treesit-node-parent p))))
                        t)))
               (bnode (and node
                           (treesit-parent-until
                            node
                            (lambda (n)
                              (and (treesit-node-check n 'named)
                                   (treesit-node-parent n)
                                   (> (line-number-at-pos (treesit-node-end n))
                                      (line-number-at-pos (treesit-node-start n)))))
                            t)))
               (b (or bnode a)))
          (if b
              (let ((bs (treesit-node-start b))
                    (be (treesit-node-end b))
                    (as (and a (treesit-node-start a)))
                    (ae (and a (treesit-node-end a))))
                (list :a-start (and as (line-number-at-pos as))
                      :a-end   (and ae (line-number-at-pos ae))
                      :a-sig   (and as (claude-code-ide-mcp--grep-block-first-line as))
                      :b-type  (treesit-node-type b)
                      :b-start (line-number-at-pos bs)
                      :b-end   (line-number-at-pos be)
                      :b-source (buffer-substring-no-properties bs be)))
            (claude-code-ide-mcp--grep-block-window line)))
      (claude-code-ide-mcp--grep-block-window line))))

(defun claude-code-ide-mcp--grep-block-collect (matches)
  "Turn MATCHES (list of (FILE . LINE)) into deduped block records.
Each record is the extract plist plus :file and :matched (line list).
Records sharing a (:b-start :b-end) within a file are merged."
  (let ((by-file (make-hash-table :test 'equal))
        (blocks '()))
    (dolist (m matches)
      (push (cdr m) (gethash (car m) by-file)))
    (maphash
     (lambda (file lines)
       (let ((inhibit-redisplay t))
         (with-current-buffer (or (find-buffer-visiting file)
                                  (find-file-noselect file))
           (save-excursion
             (let ((seen (make-hash-table :test 'equal)))
               (dolist (line (sort (copy-sequence lines) #'<))
                 (let* ((blk (claude-code-ide-mcp--grep-block-extract line))
                        (key (list (plist-get blk :b-start)
                                   (plist-get blk :b-end)))
                        (rec (gethash key seen)))
                   (if rec
                       (setf (plist-get rec :matched)
                             (cons line (plist-get rec :matched)))
                     (let ((newrec (append (list :file file :matched (list line))
                                           blk)))
                       (puthash key newrec seen)
                       (push newrec blocks))))))))))
     by-file)
    (nreverse blocks)))

(defun claude-code-ide-mcp--grep-block-render-one (rec)
  "Render one block record REC to a numbered source string."
  (let* ((matched (plist-get rec :matched))
         (a-sig (plist-get rec :a-sig))
         (a-start (plist-get rec :a-start))
         (a-end (plist-get rec :a-end))
         (b-type (plist-get rec :b-type))
         (b-start (plist-get rec :b-start))
         (b-end (plist-get rec :b-end))
         (src-lines (split-string (plist-get rec :b-source) "\n"))
         (n b-start)
         (rendered '()))
    (dolist (l src-lines)
      (push (format "    %s%d  %s" (if (memq n matched) "▶ " "  ") n l) rendered)
      (setq n (1+ n)))
    (concat
     (if a-sig (format "  %s  [%d-%d]\n" a-sig a-start a-end)
       "  (no enclosing declaration)\n")
     (format "  block %s[%d-%d]:\n" (if b-type (concat b-type " ") "") b-start b-end)
     (string-join (nreverse rendered) "\n"))))

(defun claude-code-ide-mcp--grep-block-render-header (rec)
  "One-line header for REC: block type, A signature, B range.  No source."
  (format "%s%s[%d-%d]"
          (if (plist-get rec :b-type) (concat (plist-get rec :b-type) "  ") "")
          (if (plist-get rec :a-sig) (concat (plist-get rec :a-sig) "  ") "")
          (plist-get rec :b-start)
          (plist-get rec :b-end)))

(defun claude-code-ide-mcp--grep-block-render-grouped (recs base render-fn)
  "Group RECS by file, render each with RENDER-FN under a file header.
File names are relative to BASE."
  (let ((by-file (make-hash-table :test 'equal))
        (order '()))
    (dolist (rec recs)
      (let ((f (plist-get rec :file)))
        (unless (gethash f by-file) (push f order))
        (push rec (gethash f by-file))))
    (mapconcat
     (lambda (f)
       (concat "\n" (file-relative-name f base) "\n"
               (mapconcat render-fn (nreverse (gethash f by-file)) "\n")))
     (nreverse order) "")))

(defun claude-code-ide-mcp-grep-block (pattern &optional path cap headers)
  "Search PATTERN with rg; expand each hit to its enclosing tree-sitter block.
PATH is the search root (default: project root / cwd).  CAP limits distinct
blocks (default 20; 0 = unlimited).  When HEADERS is non-nil, return every
block as a headers-only line (block type, signature, range; no source, CAP
ignored) — a cheap full survey to expand from.  Otherwise shows the tightest
enclosing block source and reports the enclosing top-level declaration's range."
  (condition-case err
      (let* ((cap (if (numberp cap) cap 20))
             (matches (claude-code-ide-mcp--grep-block-search pattern path)))
        (if (null matches)
            "No matches."
          (let* ((root (claude-code-ide-mcp--grep-block-root path))
                 (base (if (file-directory-p root) root
                         (file-name-directory root)))
                 (blocks (claude-code-ide-mcp--grep-block-collect matches))
                 (sorted (sort blocks
                               (lambda (x y)
                                 (let ((fx (plist-get x :file))
                                       (fy (plist-get y :file)))
                                   (if (string= fx fy)
                                       (< (plist-get x :b-start)
                                          (plist-get y :b-start))
                                     (string< fx fy))))))
                 (total (length sorted)))
            (if headers
                (concat
                 (format "%d blocks total (%d matches), headers only\n"
                         total (length matches))
                 (claude-code-ide-mcp--grep-block-render-grouped
                  sorted base
                  (lambda (rec)
                    (concat "  " (claude-code-ide-mcp--grep-block-render-header rec)))))
              (let* ((over (and (> cap 0) (> total cap)))
                     (kept (if over (seq-take sorted cap) sorted))
                     (omitted (if over (seq-drop sorted cap) nil))
                     (shown (length kept)))
                (concat
                 (format "%d blocks total (%d matches), showing %d\n"
                         total (length matches) shown)
                 (claude-code-ide-mcp--grep-block-render-grouped
                  kept base #'claude-code-ide-mcp--grep-block-render-one)
                 (when omitted
                   (concat
                    (format "\n\n... %d more (headers only, re-run with higher cap or headers mode to expand):\n"
                            (length omitted))
                    (mapconcat
                     (lambda (rec)
                       (concat "  " (file-relative-name (plist-get rec :file) base)
                               "  " (claude-code-ide-mcp--grep-block-render-header rec)))
                     omitted "\n")))))))))
    (error (format "Error: %s" (error-message-string err)))))

(claude-code-ide-make-tool
    :function #'claude-code-ide-mcp-grep-block
    :name "grep-block"
    :description "ripgrep search; each hit expanded to its enclosing tree-sitter block source, with the top-level declaration's range. Blocks are tagged with node type; truncated results list omitted blocks as headers. Args: pattern (rg regex), path (optional root, default project), cap (optional max blocks, default 20, 0=unlimited), headers (optional; non-empty = headers-only survey, no source, cap ignored)."
    :args '((:name "pattern"
             :type string
             :description "ripgrep regex pattern")
            (:name "path"
             :type string
             :description "Search root dir or file (optional; default project root)")
            (:name "cap"
             :type number
             :description "Max distinct blocks (optional; default 20, 0=unlimited)")
            (:name "headers"
             :type string
             :description "Non-empty = headers-only survey: block type + signature + range for every hit, no source, cap ignored")))

(provide 'claude-code-ide-extra-search)
;;; claude-code-ide-extra-search.el ends here
