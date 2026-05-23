;;; claude-code-ide-extra-lsp-nav-position.el --- MCP tools: LSP position/identifier navigation -*- lexical-binding: t; -*-
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

(provide 'claude-code-ide-extra-lsp-nav-position)
;;; claude-code-ide-extra-lsp-nav-position.el ends here