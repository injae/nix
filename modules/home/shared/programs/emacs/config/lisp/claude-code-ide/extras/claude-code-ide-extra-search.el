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

(provide 'claude-code-ide-extra-search)
;;; claude-code-ide-extra-search.el ends here
