;;; claude-code-ide-extra-lsp-nav-workspace.el --- MCP tools: LSP workspace/symbol navigation -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(require 'claude-code-ide-mcp-server)
(require 'claude-code-ide-extra-lsp-nav-position)
(require 'claude-code-ide-extra-buffer-info)

(defun claude-code-ide-mcp--eglot-buffer-for-project (file-path)
  "Return a buffer with an active eglot server for FILE-PATH's project.
Prefers an already-open buffer to avoid triggering Emacs hooks."
  (or (find-buffer-visiting file-path)
      (when-let* ((dir (file-name-directory (expand-file-name file-path)))
                  (proj (ignore-errors (project-current nil dir)))
                  (root (expand-file-name (project-root proj))))
        (seq-find
         (lambda (buf)
           (and (buffer-file-name buf)
                (string-prefix-p root (expand-file-name (buffer-file-name buf)))
                (with-current-buffer buf (eglot-current-server))))
         (buffer-list)))
      (find-file-noselect file-path)))

(defun claude-code-ide-mcp-lsp-workspace-symbols (query file-path)
  "Search for symbols matching QUERY project-wide via LSP workspace/symbol.
FILE-PATH is any file in the project to locate the eglot server context."
  (condition-case err
      (claude-code-ide-mcp-server-with-session-context nil
        (with-current-buffer (claude-code-ide-mcp--eglot-buffer-for-project file-path)
          (let ((server (eglot-current-server)))
            (unless server
              (error "No eglot server running in %s" file-path))
            (let* ((result (eglot--request server :workspace/symbol `(:query ,query)))
                   (symbols (if (vectorp result) (append result nil) result)))
              (if (null symbols)
                  (format "No symbols found for query: %s" query)
                (format "Symbols matching '%s' (%d):\n\n%s"
                        query
                        (length symbols)
                        (mapconcat
                         (lambda (sym)
                           (let* ((name (plist-get sym :name))
                                  (container (plist-get sym :containerName))
                                  (location (plist-get sym :location))
                                  (uri (plist-get location :uri))
                                  (range (plist-get location :range))
                                  (line (1+ (plist-get (plist-get range :start) :line)))
                                  (file (string-remove-prefix "file://" (url-unhex-string uri))))
                             (format "%s:%d  %s%s"
                                     file line name
                                     (if (and container (not (string-empty-p container)))
                                         (format " [%s]" container)
                                       ""))))
                         symbols "\n")))))))
    (error (format "Error: %s" (error-message-string err)))))

(claude-code-ide-make-tool
    :function #'claude-code-ide-mcp-lsp-workspace-symbols
    :name "lsp-ws-symbols"
    :description "Project-wide symbol search via LSP (workspace/symbol). Includes external packages. Use lsp_proj_symbols to exclude them."
    :args '((:name "query"
             :type string
             :description "Symbol name or partial name to search for")
            (:name "file_path"
             :type string
             :description "Absolute path to any file in the project (used to find the eglot server)")))

(defun claude-code-ide-mcp-lsp-project-symbols (query file-path)
  "Search for symbols matching QUERY within the project root only.
Filters out external packages (/go/pkg/mod/, /nix/store/)."
  (condition-case err
      (claude-code-ide-mcp-server-with-session-context nil
        (with-current-buffer (claude-code-ide-mcp--eglot-buffer-for-project file-path)
          (let ((server (eglot-current-server)))
            (unless server
              (error "No eglot server running in %s" file-path))
            (let* ((project-root
                    (when-let* ((proj (project-current
                                       nil
                                       (file-name-directory (expand-file-name file-path)))))
                      (expand-file-name (project-root proj))))
                   (result (eglot--request server :workspace/symbol `(:query ,query)))
                   (symbols (if (vectorp result) (append result nil) result))
                   (project-symbols
                    (seq-filter
                     (lambda (sym)
                       (when-let* ((loc (plist-get sym :location))
                                   (uri (plist-get loc :uri))
                                   (file (string-remove-prefix "file://" (url-unhex-string uri))))
                         (and project-root (string-prefix-p project-root file))))
                     symbols)))
              (if (null project-symbols)
                  (format "No project symbols found for query: %s" query)
                (format "Project symbols matching '%s' (%d):\n\n%s"
                        query
                        (length project-symbols)
                        (mapconcat
                         (lambda (sym)
                           (let* ((name (plist-get sym :name))
                                  (container (plist-get sym :containerName))
                                  (loc (plist-get sym :location))
                                  (uri (plist-get loc :uri))
                                  (range (plist-get loc :range))
                                  (line (1+ (plist-get (plist-get range :start) :line)))
                                  (file (string-remove-prefix "file://" (url-unhex-string uri))))
                             (format "%s:%d  %s%s"
                                     file line name
                                     (if (and container (not (string-empty-p container)))
                                         (format " [%s]" container)
                                       ""))))
                         project-symbols "\n")))))))
    (error (format "Error: %s" (error-message-string err)))))

(claude-code-ide-make-tool
    :function #'claude-code-ide-mcp-lsp-project-symbols
    :name "lsp-proj-symbols"
    :description "Project-only symbol search via LSP (no external package noise). Prefer over lsp_ws_symbols for project-internal searches."
    :args '((:name "query"
             :type string
             :description "Symbol name or partial name to search for")
            (:name "file_path"
             :type string
             :description "Absolute path to any file in the project (used to find the eglot server and project root)")))

(defun claude-code-ide-mcp--resolve-symbol-location (identifier file-path)
  "Return plist (:file :line :col) for IDENTIFIER's definition via workspace/symbol.
Prefers the symbol in the same directory as FILE-PATH, then any project-local match."
  (let ((inhibit-redisplay t))
    (claude-code-ide-mcp-server-with-session-context nil
      (with-current-buffer (claude-code-ide-mcp--eglot-buffer-for-project file-path)
        (let* ((server (eglot-current-server))
               (preferred-dir (file-name-directory (expand-file-name file-path)))
               (project-root
                (when-let* ((proj (project-current
                                   nil
                                   (file-name-directory (expand-file-name file-path)))))
                  (expand-file-name (project-root proj))))
               (raw (when server
                      (eglot--request server :workspace/symbol `(:query ,identifier))))
               (symbols (cond ((vectorp raw) (append raw nil))
                              ((listp raw) raw)
                              (t nil)))
               (project-matches
                (seq-filter
                 (lambda (sym)
                   (when-let* ((loc  (plist-get sym :location))
                               (uri  (plist-get loc :uri))
                               (file (string-remove-prefix "file://" (url-unhex-string uri))))
                     (and (string= (plist-get sym :name) identifier)
                          (or (null project-root)
                              (string-prefix-p project-root file)))))
                 symbols))
               (matched
                (or (seq-find
                     (lambda (sym)
                       (when-let* ((loc  (plist-get sym :location))
                                   (uri  (plist-get loc :uri))
                                   (file (string-remove-prefix "file://" (url-unhex-string uri))))
                         (string= (file-name-directory file) preferred-dir)))
                     project-matches)
                    (car project-matches))))
          (when matched
            (let* ((loc   (plist-get matched :location))
                   (uri   (plist-get loc :uri))
                   (range (plist-get loc :range))
                   (start (plist-get range :start)))
              (list :file (string-remove-prefix "file://" (url-unhex-string uri))
                    :line (1+ (plist-get start :line))
                    :col  (plist-get start :character)))))))))

(defun claude-code-ide-mcp-lsp-find-references-by-name (identifier file-path)
  "Find all references to IDENTIFIER by name, without needing its file position.
Resolves definition via workspace/symbol then calls textDocument/references."
  (condition-case err
      (let ((def (claude-code-ide-mcp--resolve-symbol-location identifier file-path)))
        (if (null def)
            (format "Symbol '%s' not found in project. Try lsp-find-references with an explicit position." identifier)
          (claude-code-ide-mcp--at-position
           (plist-get def :file)
           (plist-get def :line)
           (plist-get def :col)
           (lambda ()
             (let* ((server (eglot-current-server))
                    (result (eglot--request server :textDocument/references
                                            (append (claude-code-ide-mcp--textdoc-position-params)
                                                    '(:context (:includeDeclaration :json-false)))))
                    (locations (cond
                                ((null result) nil)
                                ((vectorp result) (append result nil))
                                (t (list result)))))
               (claude-code-ide-mcp--format-locations
                (format "References to '%s'" identifier)
                locations))))))
    (error (format "Error finding references: %s" (error-message-string err)))))

(claude-code-ide-make-tool
    :function #'claude-code-ide-mcp-lsp-find-references-by-name
    :name "lsp-refs-by-name"
    :description "Find all references to a symbol by name (no position needed). Use for functions/types; use lsp_refs for struct fields. Falls back with a message if not found."
    :args '((:name "identifier"
             :type string
             :description "Exact symbol name to find references for")
            (:name "file_path"
             :type string
             :description "Absolute path to any file in the project (used to locate the eglot server and project root)")))

(defun claude-code-ide-mcp-def-source (identifier file-path)
  "Find IDENTIFIER's definition via workspace/symbol and return its full source.
Combines symbol resolution + symbol_source in one call."
  (condition-case err
      (let ((def (claude-code-ide-mcp--resolve-symbol-location identifier file-path)))
        (if (null def)
            (format "Symbol '%s' not found in project." identifier)
          (claude-code-ide-mcp-symbol-source
           (plist-get def :file)
           (plist-get def :line))))
    (error (format "Error: %s" (error-message-string err)))))

(claude-code-ide-make-tool
    :function #'claude-code-ide-mcp-def-source
    :name "def-source"
    :description "Find a symbol's definition and return its full source in one call (lsp_def + symbol_source). Use instead of the two-step pipeline when you want the source of a known symbol."
    :args '((:name "identifier"
             :type string
             :description "Symbol name to look up")
            (:name "file_path"
             :type string
             :description "Absolute path to any file in the project")))

(provide 'claude-code-ide-extra-lsp-nav-workspace)
;;; claude-code-ide-extra-lsp-nav-workspace.el ends here