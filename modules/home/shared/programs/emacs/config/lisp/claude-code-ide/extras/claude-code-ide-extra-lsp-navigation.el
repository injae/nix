;;; claude-code-ide-extra-lsp-navigation.el --- MCP tools: LSP code navigation -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(require 'claude-code-ide-mcp-server)

(defun claude-code-ide-mcp--format-xrefs (label xrefs)
  "Format XREFS list into a readable string under LABEL."
  (if (null xrefs)
      (format "No %s found." label)
    (format "%s (%d):\n\n%s"
            label
            (length xrefs)
            (mapconcat
             (lambda (xref)
               (let ((loc (xref-item-location xref)))
                 (format "%s:%s  %s"
                         (xref-location-group loc)
                         (or (ignore-errors (number-to-string (xref-location-line loc))) "?")
                         (substring-no-properties (xref-item-summary xref)))))
             xrefs "\n"))))

(defun claude-code-ide-mcp--with-identifier (file-path identifier fn)
  "In FILE-PATH, search for IDENTIFIER, position cursor there, call FN."
  (let ((inhibit-redisplay t))
    (claude-code-ide-mcp-server-with-session-context nil
      (with-current-buffer (or (find-buffer-visiting file-path)
                               (find-file-noselect file-path))
        (save-excursion
          (goto-char (point-min))
          (if (search-forward identifier nil t)
              (progn
                (backward-char (length identifier))
                (funcall fn))
            (format "Identifier '%s' not found in %s" identifier file-path)))))))

(defun claude-code-ide-mcp--at-position (file-path line column fn)
  "In FILE-PATH, move to LINE (1-based) COLUMN (0-based), call FN."
  (let ((inhibit-redisplay t))
    (claude-code-ide-mcp-server-with-session-context nil
      (with-current-buffer (or (find-buffer-visiting file-path)
                               (find-file-noselect file-path))
        (save-excursion
          (goto-char (point-min))
          (when (and line (> line 0))
            (forward-line (1- line)))
          (when (and column (>= column 0))
            (move-to-column column))
          (funcall fn))))))

(defun claude-code-ide-mcp-lsp-find-definition (identifier file-path)
  "Find definition of IDENTIFIER via xref backend in FILE-PATH context."
  (condition-case err
      (claude-code-ide-mcp--with-identifier
       file-path identifier
       (lambda ()
         (claude-code-ide-mcp--format-xrefs
          (format "Definitions of '%s'" identifier)
          (xref-backend-definitions (xref-find-backend) identifier))))
    (error (format "Error finding definition: %s" (error-message-string err)))))

(defun claude-code-ide-mcp--textdoc-position-params ()
  "Return LSP TextDocumentPositionParams for the current buffer and point."
  `(:textDocument (:uri ,(eglot--path-to-uri (buffer-file-name)))
    :position (:line ,(1- (line-number-at-pos)) :character ,(current-column))))

(defun claude-code-ide-mcp--format-locations (label locations)
  "Format LSP Location[] LOCATIONS into a readable string under LABEL."
  (if (null locations)
      (format "No %s found." label)
    (format "%s (%d):\n\n%s"
            label
            (length locations)
            (mapconcat
             (lambda (loc)
               (let* ((uri (plist-get loc :uri))
                      (range (plist-get loc :range))
                      (line (1+ (plist-get (plist-get range :start) :line)))
                      (file (string-remove-prefix "file://" (url-unhex-string uri))))
                 (format "%s:%d" file line)))
             locations "\n"))))

(defun claude-code-ide-mcp-lsp-find-implementation (file-path line column)
  "Find implementations at FILE-PATH LINE:COLUMN via eglot textDocument/implementation."
  (condition-case err
      (claude-code-ide-mcp--at-position
       file-path line column
       (lambda ()
         (let* ((server (eglot-current-server))
                (result (eglot--request server :textDocument/implementation
                                        (claude-code-ide-mcp--textdoc-position-params)))
                (locations (cond
                            ((null result) nil)
                            ((vectorp result) (append result nil))
                            (t (list result)))))
           (claude-code-ide-mcp--format-locations "Implementations" locations))))
    (error (format "Error finding implementation: %s" (error-message-string err)))))

(defun claude-code-ide-mcp-lsp-find-typeDefinition (file-path line column)
  "Find type definition at FILE-PATH LINE:COLUMN via eglot textDocument/typeDefinition."
  (condition-case err
      (claude-code-ide-mcp--at-position
       file-path line column
       (lambda ()
         (let* ((server (eglot-current-server))
                (result (eglot--request server :textDocument/typeDefinition
                                        (claude-code-ide-mcp--textdoc-position-params)))
                (locations (cond
                            ((null result) nil)
                            ((vectorp result) (append result nil))
                            (t (list result)))))
           (claude-code-ide-mcp--format-locations "Type definitions" locations))))
    (error (format "Error finding type definition: %s" (error-message-string err)))))

(defun claude-code-ide-mcp-lsp-find-references (file-path line column)
  "Find all references to the symbol at FILE-PATH LINE:COLUMN via eglot."
  (condition-case err
      (claude-code-ide-mcp--at-position
       file-path line column
       (lambda ()
         (let* ((server (eglot-current-server))
                (result (eglot--request server :textDocument/references
                                        (append (claude-code-ide-mcp--textdoc-position-params)
                                                '(:context (:includeDeclaration :json-false)))))
                (locations (cond
                            ((null result) nil)
                            ((vectorp result) (append result nil))
                            (t (list result)))))
           (claude-code-ide-mcp--format-locations "References" locations))))
    (error (format "Error finding references: %s" (error-message-string err)))))

(claude-code-ide-make-tool
    :function #'claude-code-ide-mcp-lsp-find-definition
    :name "claude-code-ide-mcp-lsp-find-definition"
    :description "Find the definition(s) of a symbol using the eglot/LSP xref backend. Prefer this over grep or find — the language server returns precise results including cross-file definitions. Pass the symbol name and any file in the project as context to initialize the backend."
    :args '((:name "identifier"
             :type string
             :description "The symbol name to find the definition for")
            (:name "file_path"
             :type string
             :description "Absolute path to any file in the project (used to initialize the eglot/xref backend)")))

(claude-code-ide-make-tool
    :function #'claude-code-ide-mcp-lsp-find-implementation
    :name "claude-code-ide-mcp-lsp-find-implementation"
    :description "Find implementations of an interface or abstract symbol at a file position using eglot (textDocument/implementation). Position the cursor on the symbol by providing file path, line (1-based), and column (0-based)."
    :args '((:name "file_path"
             :type string
             :description "Absolute path to the file containing the symbol")
            (:name "line"
             :type number
             :description "Line number (1-based) where the symbol appears")
            (:name "column"
             :type number
             :description "Column number (0-based) where the symbol starts")))

(claude-code-ide-make-tool
    :function #'claude-code-ide-mcp-lsp-find-typeDefinition
    :name "claude-code-ide-mcp-lsp-find-typeDefinition"
    :description "Find the type definition of a symbol at a file position using eglot (textDocument/typeDefinition). Useful for tracing the declared type behind a variable or parameter. Provide file path, line (1-based), and column (0-based)."
    :args '((:name "file_path"
             :type string
             :description "Absolute path to the file containing the symbol")
            (:name "line"
             :type number
             :description "Line number (1-based) where the symbol appears")
            (:name "column"
             :type number
             :description "Column number (0-based) where the symbol starts")))

(claude-code-ide-make-tool
    :function #'claude-code-ide-mcp-lsp-find-references
    :name "claude-code-ide-mcp-lsp-find-references"
    :description "Find all call sites / references to the symbol at a file position using eglot (textDocument/references). Use this to find every location that uses a function, variable, or type. Provide file path, line (1-based), and column (0-based) pointing to the symbol."
    :args '((:name "file_path"
             :type string
             :description "Absolute path to the file containing the symbol")
            (:name "line"
             :type number
             :description "Line number (1-based) where the symbol appears")
            (:name "column"
             :type number
             :description "Column number (0-based) where the symbol starts")))

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
    :name "claude-code-ide-mcp-lsp-workspace-symbols"
    :description "Search for symbols matching a query string across the entire project using LSP workspace/symbol. Equivalent to consult-eglot-symbol but non-interactive. Use this INSTEAD of grep/find/rg whenever you need to locate a symbol, type, function, or variable by name."
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
    :name "claude-code-ide-mcp-lsp-project-symbols"
    :description "Search for symbols matching a query string within the current project only, using LSP workspace/symbol. Identical to lsp-workspace-symbols but filters out external packages (/go/pkg/mod/, /nix/store/, etc.). Use this when you only care about project-local definitions and want less noise."
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
    :name "claude-code-ide-mcp-lsp-find-references-by-name"
    :description "Find all references to a symbol by name, without needing its file position. Internally resolves the definition via workspace/symbol (project-local, exact name match), then calls textDocument/references. Use this instead of the two-step lsp-project-symbols → lsp-find-references workflow. Falls back with a clear message if the symbol is not found."
    :args '((:name "identifier"
             :type string
             :description "Exact symbol name to find references for (e.g. \"RetryTask\", \"NewManagedTask\")")
            (:name "file_path"
             :type string
             :description "Absolute path to any file in the project (used to locate the eglot server and project root)")))

(provide 'claude-code-ide-extra-lsp-navigation)
;;; claude-code-ide-extra-lsp-navigation.el ends here