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
                      :b-start (line-number-at-pos bs)
                      :b-end   (line-number-at-pos be)
                      :b-source (buffer-substring-no-properties bs be)))
            (claude-code-ide-mcp--grep-block-window line)))
      (claude-code-ide-mcp--grep-block-window line))))

(provide 'claude-code-ide-extra-search)
;;; claude-code-ide-extra-search.el ends here
