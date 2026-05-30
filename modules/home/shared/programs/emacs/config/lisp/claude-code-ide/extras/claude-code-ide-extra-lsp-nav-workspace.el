;;; claude-code-ide-extra-lsp-nav-workspace.el --- MCP tools: LSP workspace/symbol navigation -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(require 'claude-code-ide-mcp-server)
(require 'claude-code-ide-extra-lsp-nav-position)
(require 'claude-code-ide-extra-buffer-info)

(defun claude-code-ide-mcp--eglot-buffer-for-project (file-path)
  "Return a buffer with an active eglot server for FILE-PATH's project.
Starts eglot via eglot--connect if no server is already running."
  (let ((buf (or (find-buffer-visiting file-path)
                 (when-let* ((dir (file-name-directory (expand-file-name file-path)))
                             (proj (ignore-errors (project-current nil dir)))
                             (root (expand-file-name (project-root proj))))
                   (seq-find
                    (lambda (b)
                      (and (buffer-file-name b)
                           (string-prefix-p root (expand-file-name (buffer-file-name b)))
                           (with-current-buffer b (eglot-current-server))))
                    (buffer-list)))
                 (let ((delay-mode-hooks t))
                   (find-file-noselect file-path)))))
    (with-current-buffer buf
      (claude-code-ide-mcp--ensure-eglot file-path))
    buf))

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
    :description "Workspace symbol search via LSP. Includes external pkgs. Use lsp_proj_symbols to exclude."
    :args '((:name "query"
             :type string
             :description "Symbol name or partial")
            (:name "file_path"
             :type string
             :description "Any project file (finds eglot server)")))

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
    :description "Project-only symbol search via LSP. No external pkg noise. Prefer over lsp_ws_symbols."
    :args '((:name "query"
             :type string
             :description "Symbol name or partial")
            (:name "file_path"
             :type string
             :description "Any project file (finds eglot server and root)")))

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
    :description "All refs to symbol by name, no position needed. For fns/types; use lsp_refs for struct fields. Falls back with message."
    :args '((:name "identifier"
             :type string
             :description "Exact symbol name")
            (:name "file_path"
             :type string
             :description "Any project file (finds eglot server and root)")))

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
    :description "Symbol definition + full source in one call (lsp_def + symbol_source). Skip two-step pipeline."
    :args '((:name "identifier"
             :type string
             :description "Symbol name")
            (:name "file_path"
             :type string
             :description "Any project file")))

(provide 'claude-code-ide-extra-lsp-nav-workspace)
;;; claude-code-ide-extra-lsp-nav-workspace.el ends here