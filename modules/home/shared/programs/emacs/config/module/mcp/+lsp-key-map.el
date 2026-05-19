;;; +lsp-key-map.el --- MCP tools: LSP code navigation -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

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
  "In FILE-PATH, search for IDENTIFIER, position cursor there, call FN.
Uses session context and restores cursor position afterward via save-excursion.
inhibit-redisplay prevents visible cursor jumps in open windows."
  (claude-code-ide-mcp-server-with-session-context nil
    (with-current-buffer (or (find-buffer-visiting file-path)
                             (find-file-noselect file-path))
      (let ((inhibit-redisplay t))
        (save-excursion
          (goto-char (point-min))
          (if (search-forward identifier nil t)
              (progn
                (backward-char (length identifier))
                (funcall fn))
            (format "Identifier '%s' not found in %s" identifier file-path)))))))

(defun claude-code-ide-mcp--at-position (file-path line column fn)
  "In FILE-PATH, move to LINE (1-based) COLUMN (0-based), call FN.
Uses session context and restores cursor position afterward via save-excursion.
inhibit-redisplay prevents visible cursor jumps in open windows."
  (claude-code-ide-mcp-server-with-session-context nil
    (with-current-buffer (or (find-buffer-visiting file-path)
                             (find-file-noselect file-path))
      (let ((inhibit-redisplay t))
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

(defun claude-code-ide-mcp-lsp-find-references (identifier file-path)
  "Find all references to IDENTIFIER via LSP in FILE-PATH context."
  (condition-case err
      (claude-code-ide-mcp--with-identifier
       file-path identifier
       (lambda ()
         (claude-code-ide-mcp--format-xrefs
          (format "References to '%s'" identifier)
          (xref-backend-references (xref-find-backend) identifier))))
    (error (format "Error finding references: %s" (error-message-string err)))))

(defun claude-code-ide-mcp-lsp-find-implementation (file-path line column)
  "Find implementations at FILE-PATH LINE:COLUMN via eglot."
  (condition-case err
      (claude-code-ide-mcp--at-position
       file-path line column
       (lambda ()
         (claude-code-ide-mcp--format-xrefs
          "Implementations"
          (eglot--lsp-xref-helper :textDocument/implementation))))
    (error (format "Error finding implementation: %s" (error-message-string err)))))

(defun claude-code-ide-mcp-lsp-find-typeDefinition (file-path line column)
  "Find type definition at FILE-PATH LINE:COLUMN via eglot."
  (condition-case err
      (claude-code-ide-mcp--at-position
       file-path line column
       (lambda ()
         (claude-code-ide-mcp--format-xrefs
          "Type definitions"
          (eglot--lsp-xref-helper :textDocument/typeDefinition))))
    (error (format "Error finding type definition: %s" (error-message-string err)))))

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
    :function #'claude-code-ide-mcp-lsp-find-references
    :name "claude-code-ide-mcp-lsp-find-references"
    :description "Find all references to a symbol using the eglot/LSP xref backend. Prefer this over grep or find — the language server returns precise call sites. Pass the symbol name and any file in the project as context."
    :args '((:name "identifier"
             :type string
             :description "The symbol name to find all references for")
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

(defun claude-code-ide-mcp-lsp-workspace-symbols (query file-path)
  "Search for symbols matching QUERY project-wide via LSP workspace/symbol.
FILE-PATH is any file in the project to initialize the eglot server context."
  (condition-case err
      (claude-code-ide-mcp-server-with-session-context nil
        (with-current-buffer (or (find-buffer-visiting file-path)
                                 (find-file-noselect file-path))
          (let* ((server (eglot-current-server)))
            (unless server
              (error "No eglot server running in %s" file-path))
            (let* ((result (eglot--request server :workspace/symbol
                                           `(:query ,query)))
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
                                  (line (1+ (plist-get
                                             (plist-get range :start) :line)))
                                  (file (string-remove-prefix
                                         "file://"
                                         (url-unhex-string uri))))
                             (format "%s:%d  %s%s"
                                     file line name
                                     (if (and container
                                              (not (string-empty-p container)))
                                         (format " [%s]" container)
                                       ""))))
                         symbols
                         "\n")))))))
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

(provide '+lsp-key-map)
;;; +lsp-key-map.el ends here
