;;; claude-code-ide-extra-edit.el --- MCP tools: structural rewrite -*- lexical-binding: t; -*-
;;; Commentary:
;; ast-rewrite: structural find-and-replace through the ast-grep CLI.  Matching
;; runs on the syntax tree, so whitespace, line breaks and lookalike text in
;; comments or strings cannot move an edit to the wrong place.  Searching is
;; not part of this tool -- `grep-block' already covers it.
;;
;; The wrapper adds what calling the CLI from a shell cannot: it refuses to
;; write while a target file has unsaved changes in Emacs, reverts the buffers
;; it rewrote, and answers a pattern that matched nothing with the pattern's
;; own parse tree instead of silence.
;;; Code:

(require 'claude-code-ide-mcp-server)

(defun claude-code-ide-mcp--sg-executable ()
  "Return the ast-grep program, or signal when it is not installed."
  (or (executable-find "ast-grep")
      (error "ast-grep not found in exec-path")))

(defun claude-code-ide-mcp--sg-run (args)
  "Run ast-grep with ARGS.  Return a plist of :exit, :out and :err.
Neither channel decides success alone: ast-grep exits 1 with empty output
when a pattern simply matched nothing, and writes its \"Applied N changes\"
summary to stderr on a successful rewrite."
  ;; Resolved outside `with-temp-buffer': `executable-find' returns nil there.
  (let ((program (claude-code-ide-mcp--sg-executable))
        (stderr (make-temp-file "claude-code-ide-sg")))
    (unwind-protect
        (with-temp-buffer
          (let ((exit (apply #'process-file program nil (list t stderr) nil args)))
            (list :exit exit
                  :out (buffer-string)
                  :err (with-temp-buffer
                         (insert-file-contents stderr)
                         (buffer-string)))))
      (delete-file stderr))))

(defun claude-code-ide-mcp--sg-failure (result)
  "Return the error text when RESULT is a real failure, else nil."
  (let ((err (string-trim (plist-get result :err))))
    (unless (or (eq 0 (plist-get result :exit)) (string-empty-p err))
      err)))

(defun claude-code-ide-mcp--sg-args (pattern path rewrite lang globs strictness)
  "Build the ast-grep argument list for PATTERN over PATH.
REWRITE, LANG, GLOBS and STRICTNESS are added when non-empty."
  (append (list "run" "--color" "never" "-p" pattern)
          (when (and rewrite (not (string-empty-p rewrite))) (list "-r" rewrite))
          (when (and lang (not (string-empty-p lang))) (list "-l" lang))
          (when (and globs (not (string-empty-p globs))) (list "--globs" globs))
          (when (and strictness (not (string-empty-p strictness)))
            (list "--strictness" strictness))
          (list path)))

(defun claude-code-ide-mcp--sg-explain (pattern lang)
  "Return the parse tree ast-grep built for PATTERN, or advice when it cannot.
LANG is required by --debug-query, so without it only advice is returned."
  (if (or (null lang) (string-empty-p lang))
      "Pass lang to see how ast-grep parsed the pattern (--debug-query needs it)."
    (let ((result (claude-code-ide-mcp--sg-run
                   (list "run" "--color" "never" "--debug-query=ast"
                         "-l" lang "-p" pattern "--stdin"))))
      (concat "pattern parsed as:\n"
              (plist-get result :err)
              (plist-get result :out)))))

(defun claude-code-ide-mcp--sg-dirty-files (root)
  "Return files under ROOT whose Emacs buffer has unsaved changes."
  (delq nil
        (mapcar (lambda (buffer)
                  (let ((file (buffer-file-name buffer)))
                    (when (and file
                               (buffer-modified-p buffer)
                               (string-prefix-p root (expand-file-name file)))
                      file)))
                (buffer-list))))

(defun claude-code-ide-mcp--sg-revert (root)
  "Revert unmodified buffers visiting files under ROOT.  Return how many."
  (let ((count 0)
        (inhibit-redisplay t))
    (dolist (buffer (buffer-list))
      (let ((file (buffer-file-name buffer)))
        (when (and file
                   (not (buffer-modified-p buffer))
                   (string-prefix-p root (expand-file-name file))
                   (file-exists-p file))
          (with-current-buffer buffer
            (revert-buffer :ignore-auto :noconfirm))
          (setq count (1+ count)))))
    count))

(defun claude-code-ide-mcp-ast-rewrite (pattern rewrite path &optional lang globs strictness dry-run)
  "Rewrite every structural match of PATTERN under PATH to REWRITE.
PATTERN and REWRITE are code fragments; an identifier written $NAME binds a
whole node and expands again in REWRITE, and $$$NAME binds a node list.
LANG names the language, GLOBS filters paths, STRICTNESS tunes how exactly
nodes must agree.  A dry pass always runs first: a pattern matching nothing
returns its own parse tree rather than writing, and DRY-RUN stops after that
pass."
  (condition-case err
      (let* ((_ (when (or (null rewrite) (string-empty-p rewrite))
                  (error "rewrite is required; search with grep-block")))
             (path (expand-file-name path))
             (preview (claude-code-ide-mcp--sg-run
                       (claude-code-ide-mcp--sg-args
                        pattern path rewrite lang globs strictness)))
             (out (plist-get preview :out))
             (failure (claude-code-ide-mcp--sg-failure preview)))
        (cond
         (failure (format "ast-grep failed:\n%s" failure))
         ((string-empty-p (string-trim out))
          (concat (format "No match for pattern under %s.\n\n" path)
                  (claude-code-ide-mcp--sg-explain pattern lang)))
         (dry-run (concat out "\nDry run — nothing written.\n"))
         (t
          (let ((dirty (claude-code-ide-mcp--sg-dirty-files path)))
            (if dirty
                (concat "Refused to write — unsaved changes in Emacs:\n"
                        (mapconcat (lambda (f) (concat "  " f)) dirty "\n")
                        "\nSave or revert those buffers, then run again.")
              (let ((applied (claude-code-ide-mcp--sg-run
                              (append (claude-code-ide-mcp--sg-args
                                       pattern path rewrite lang globs strictness)
                                      (list "-U")))))
                (if-let ((failed (claude-code-ide-mcp--sg-failure applied)))
                    (format "ast-grep failed while writing:\n%s" failed)
                  (let ((reverted (claude-code-ide-mcp--sg-revert path)))
                    (concat out
                            (format "\n%s. %d Emacs buffers reverted.\n"
                                    (string-trim (plist-get applied :err))
                                    reverted))))))))))
    (error (format "Error: %s" (error-message-string err)))))

(claude-code-ide-make-tool
    :function #'claude-code-ide-mcp-ast-rewrite
    :name "ast-rewrite"
    :description "Structural find-and-replace over the syntax tree via the ast-grep CLI, not over buffer text. Prefer it over Edit whenever the same shape occurs more than once, indentation is uncertain, or lookalike text sits nearby -- the three ways a textual edit lands in the wrong place. Write pattern and rewrite as code fragments: $NAME binds a whole node and expands again in the rewrite (foo($A, $B) -> bar($B, $A)), $$$NAME binds a node list. Whitespace and line breaks are ignored, node kinds must agree, and text inside comments or strings never matches. This tool only rewrites -- search with grep-block. Args: pattern, rewrite, path (file or directory), lang (language name; needed to explain a failing pattern), globs (gitignore-style path filter, prefix ! to exclude), strictness (cst | smart | ast | relaxed | signature | template), dry_run (show the diff without writing). A dry pass always runs first: a pattern that matches nothing comes back with its own parse tree instead of silence, and nothing is written while a target file has unsaved changes in Emacs. Rewritten files are reverted in Emacs automatically."
    :args '((:name "pattern"
             :type string
             :description "Code fragment to match; $NAME binds one node, $$$NAME binds a node list")
            (:name "rewrite"
             :type string
             :description "Code fragment to insert; $NAME expands to what the pattern captured")
            (:name "path"
             :type string
             :description "File or directory to rewrite")
            (:name "lang"
             :type string
             :description "Language of the pattern; required to explain a pattern that matched nothing"
             :optional t)
            (:name "globs"
             :type string
             :description "gitignore-style path filter, ! to exclude"
             :optional t)
            (:name "strictness"
             :type string
             :description "cst | smart | ast | relaxed | signature | template"
             :optional t)
            (:name "dry_run"
             :type boolean
             :description "Show the diff without writing"
             :optional t)))

(provide 'claude-code-ide-extra-edit)
;;; claude-code-ide-extra-edit.el ends here
