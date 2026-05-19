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

(defun claude-code-ide-mcp--at-position (file-path line column fn)
  "Open FILE-PATH, move to LINE (1-based) COLUMN (0-based), call FN."
  (with-current-buffer (find-file-noselect file-path)
    (goto-char (point-min))
    (when (and line (> line 0))
      (forward-line (1- line)))
    (when (and column (>= column 0))
      (move-to-column column))
    (funcall fn)))

(defun claude-code-ide-mcp-lsp-find-definition (identifier file-path)
  "Find definition of IDENTIFIER via xref backend in FILE-PATH context."
  (condition-case err
      (with-current-buffer (find-file-noselect file-path)
        (let* ((backend (xref-find-backend))
               (xrefs (xref-backend-definitions backend identifier)))
          (claude-code-ide-mcp--format-xrefs
           (format "Definitions of '%s'" identifier) xrefs)))
    (error (format "Error finding definition: %s" (error-message-string err)))))

(defun claude-code-ide-mcp-lsp-find-references (identifier file-path)
  "Find all references to IDENTIFIER via xref backend in FILE-PATH context."
  (condition-case err
      (with-current-buffer (find-file-noselect file-path)
        (let* ((backend (xref-find-backend))
               (xrefs (xref-backend-references backend identifier)))
          (claude-code-ide-mcp--format-xrefs
           (format "References to '%s'" identifier) xrefs)))
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

(provide '+lsp-key-map)
;;; +lsp-key-map.el ends here
