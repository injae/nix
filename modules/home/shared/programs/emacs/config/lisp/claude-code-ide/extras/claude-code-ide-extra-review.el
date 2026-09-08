;;; claude-code-ide-extra-review.el --- MCP tools: change review -*- lexical-binding: t; -*-
;;; Commentary:
;; review-changes: the git read side a code review needs -- commit metadata,
;; per-file stat, the patch, and diff hunks expanded to their enclosing
;; tree-sitter block.
;;; Code:

(require 'claude-code-ide-mcp-server)
(require 'claude-code-ide-extra-magit)
(require 'claude-code-ide-extra-search)

(defun claude-code-ide-mcp--review-git (&rest args)
  "Run git with ARGS in `default-directory' and return stdout.
Signal an error on non-zero exit."
  (with-temp-buffer
    (let ((exit (apply #'process-file "git" nil t nil args)))
      (unless (eq exit 0)
        (error "git %s failed (exit %s): %s"
               (string-join args " ") exit (string-trim (buffer-string))))
      (buffer-string))))

(defun claude-code-ide-mcp--review-uncommitted-p (target)
  "Non-nil when TARGET names the uncommitted working tree."
  (or (null target) (string-empty-p target) (string= target "uncommitted")))

(defun claude-code-ide-mcp--review-commit-p (target)
  "Non-nil when TARGET names a single commit rather than a range or the tree."
  (and (not (claude-code-ide-mcp--review-uncommitted-p target))
       (not (string-match-p "\\.\\." target))))

(defun claude-code-ide-mcp--review-target-args (target)
  "Return the git subcommand and revision arguments selecting TARGET."
  (cond
   ((claude-code-ide-mcp--review-uncommitted-p target) (list "diff" "HEAD"))
   ((claude-code-ide-mcp--review-commit-p target) (list "show" "--format=" target))
   (t (list "diff" target))))

(defun claude-code-ide-mcp--review-run (target extra path)
  "Run the git command for TARGET with EXTRA options, limited to PATH."
  (let ((base (claude-code-ide-mcp--review-target-args target)))
    (apply #'claude-code-ide-mcp--review-git
           (append (list (car base)) extra (cdr base)
                   (when (and path (not (string-empty-p path)))
                     (list "--" path))))))

(defun claude-code-ide-mcp--review-summary (target path)
  "Return commit metadata, tree status and per-file stat for TARGET under PATH."
  (concat
   (when (claude-code-ide-mcp--review-commit-p target)
     (claude-code-ide-mcp--review-git
      "show" "--no-patch"
      "--format=commit %H%nauthor  %an <%ae>%ndate    %ad%nparent  %P%n%n%s%n%n%b"
      target))
   (when (claude-code-ide-mcp--review-uncommitted-p target)
     (let ((status (claude-code-ide-mcp--review-git "status" "--short")))
       (if (string-empty-p (string-trim status)) "clean tree\n" status)))
   (claude-code-ide-mcp--review-run target '("--stat") path)))

(defun claude-code-ide-mcp--review-changed-lines (diff root)
  "Return (ABS-FILE . NEW-LINE) cells parsed from a --unified=0 DIFF.
DIFF must come from a --no-prefix run: `diff.mnemonicPrefix' turns the
usual a/ and b/ into c/ and w/, which no fixed prefix strip survives.
Paths resolve against ROOT.  A pure-deletion hunk maps to the line it left
behind, so the block that lost code still shows up."
  (let ((file nil)
        (cells '()))
    (dolist (line (split-string diff "\n"))
      (cond
       ((string-prefix-p "+++ " line)
        (let ((path (substring line 4)))
          (setq file (unless (string= path "/dev/null")
                       (expand-file-name path root)))))
       ((and file
             (string-prefix-p "@@ " line)
             (string-match "\\+\\([0-9]+\\)\\(?:,\\([0-9]+\\)\\)?" line))
        (let ((start (string-to-number (match-string 1 line)))
              (count (if (match-string 2 line)
                         (string-to-number (match-string 2 line))
                       1)))
          (if (zerop count)
              (push (cons file (max 1 start)) cells)
            (dotimes (i count)
              (push (cons file (+ start i)) cells)))))))
    (nreverse cells)))

(defun claude-code-ide-mcp--review-sort-blocks (blocks)
  "Sort BLOCKS by file then start line."
  (sort blocks
        (lambda (x y)
          (let ((fx (plist-get x :file))
                (fy (plist-get y :file)))
            (if (string= fx fy)
                (< (plist-get x :b-start) (plist-get y :b-start))
              (string< fx fy))))))

(defun claude-code-ide-mcp--review-lines-source (file start end)
  "Return lines START through END of FILE, as text."
  (let ((inhibit-redisplay t))
    (with-current-buffer (or (claude-code-ide-mcp--refresh-visiting file)
                             (find-file-noselect file))
      (save-excursion
        (goto-char (point-min))
        (forward-line (1- start))
        (let ((from (point)))
          (goto-char (point-min))
          (forward-line (1- end))
          (buffer-substring-no-properties from (line-end-position)))))))

(defun claude-code-ide-mcp--review-merge-blocks (sorted)
  "Merge SORTED blocks whose line ranges overlap inside one file.
Changed lines are contiguous by nature, so without this a hunk in a file
tree-sitter cannot parse yields one near-identical window per line."
  (let ((merged '()))
    (dolist (rec sorted)
      (let ((prev (car merged)))
        (if (and prev
                 (string= (plist-get prev :file) (plist-get rec :file))
                 (<= (plist-get rec :b-start) (plist-get prev :b-end)))
            (let ((start (plist-get prev :b-start))
                  (end (max (plist-get prev :b-end) (plist-get rec :b-end))))
              (setf (plist-get prev :b-end) end
                    (plist-get prev :matched) (append (plist-get prev :matched)
                                                      (plist-get rec :matched))
                    (plist-get prev :b-source)
                    (claude-code-ide-mcp--review-lines-source
                     (plist-get prev :file) start end)))
          (push rec merged))))
    (nreverse merged)))

(defun claude-code-ide-mcp--review-tree-warning (target)
  "Return a staleness note unless TARGET is the working tree itself."
  (unless (claude-code-ide-mcp--review-uncommitted-p target)
    "\nNote: block source comes from the working tree, not from the revision. Use mode=diff when the tree has moved past it.\n"))

(defun claude-code-ide-mcp--review-blocks (target path cap root)
  "Render changed hunks of TARGET under PATH as tree-sitter blocks.
CAP limits distinct blocks; ROOT is the repository toplevel."
  (let* ((diff (claude-code-ide-mcp--review-run
                target '("--unified=0" "--no-prefix") path))
         (cells (seq-filter (lambda (cell) (file-readable-p (car cell)))
                            (claude-code-ide-mcp--review-changed-lines diff root))))
    (if (null cells)
        "\nNo changed line maps to a readable file in the working tree."
      (let* ((sorted (claude-code-ide-mcp--review-merge-blocks
                      (claude-code-ide-mcp--review-sort-blocks
                       (claude-code-ide-mcp--grep-block-collect cells))))
             (total (length sorted))
             (over (and (> cap 0) (> total cap)))
             (kept (if over (seq-take sorted cap) sorted))
             (omitted (and over (seq-drop sorted cap))))
        (concat
         (claude-code-ide-mcp--review-tree-warning target)
         (format "\n%d blocks changed, showing %d\n" total (length kept))
         (claude-code-ide-mcp--grep-block-render-grouped
          kept root #'claude-code-ide-mcp--grep-block-render-one)
         (when omitted
           (concat
            (format "\n\n... %d more (headers only, raise cap to expand):\n"
                    (length omitted))
            (mapconcat
             (lambda (rec)
               (concat "  " (file-relative-name (plist-get rec :file) root)
                       "  " (claude-code-ide-mcp--grep-block-render-header rec)))
             omitted "\n"))))))))

(defun claude-code-ide-mcp-review-changes (&optional target mode path cap repo-dir)
  "Report the change set of TARGET for review.
TARGET is \"uncommitted\" (default), a commit SHA, or a range like
\"main..HEAD\".  MODE is \"summary\", \"diff\" (default) or \"blocks\".
PATH limits the report to one path.  CAP limits distinct blocks in
\"blocks\" mode (default 20; 0 = unlimited).  REPO-DIR overrides the
calling session's repository."
  (condition-case err
      (let* ((root (claude-code-ide-mcp--magit-repo repo-dir))
             (default-directory root)
             (mode (if (and mode (not (string-empty-p mode))) mode "diff"))
             (cap (if (numberp cap) cap 20))
             (summary (claude-code-ide-mcp--review-summary target path)))
        (cond
         ((string= mode "summary") summary)
         ((string= mode "diff")
          (concat summary "\n" (claude-code-ide-mcp--review-run target nil path)))
         ((string= mode "blocks")
          (concat summary
                  (claude-code-ide-mcp--review-blocks target path cap root)))
         (t (error "Unknown mode: %s (summary | diff | blocks)" mode))))
    (error (format "Error: %s" (error-message-string err)))))

(claude-code-ide-make-tool
    :function #'claude-code-ide-mcp-review-changes
    :name "review-changes"
    :description "Git read side of a code review: commit metadata, per-file stat, patch, diff hunks grown to their enclosing tree-sitter block with changed lines marked. Args: target (\"uncommitted\" default, commit SHA, or range like main..HEAD), mode (summary = metadata + stat only, diff = full patch (default), blocks = hunks as tree-sitter blocks), path (limit to one path), cap (max blocks in blocks mode, default 20, 0=unlimited). Survey with summary, then read blocks. blocks mode reads block source from the working tree, so prefer diff for a revision the tree has moved past."
    :args `((:name "target"
             :type string
             :description "\"uncommitted\" (default), a commit SHA, or a range like main..HEAD"
             :optional t)
            (:name "mode"
             :type string
             :description "summary | diff (default) | blocks"
             :optional t)
            (:name "path"
             :type string
             :description "Limit the report to this path"
             :optional t)
            (:name "cap"
             :type number
             :description "Max distinct blocks in blocks mode; default 20, 0=unlimited"
             :optional t)
            ,claude-code-ide-mcp--magit-repo-arg))

(provide 'claude-code-ide-extra-review)
;;; claude-code-ide-extra-review.el ends here
