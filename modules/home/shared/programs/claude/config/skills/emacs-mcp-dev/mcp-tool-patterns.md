# MCP Tool Patterns — LSP Navigation

Reference when adding tools to `config/module/mcp/+lsp-navigation.el`.
For general MCP tool conventions (naming, registration, inhibit-redisplay) see the `emacs-mcp-dev` skill.

---

## Helper overview

These helpers in `+lsp-navigation.el` are building blocks for every pattern below.

| Helper | Purpose | Call site |
|--------|---------|-----------|
| `--at-position (file line col fn)` | Navigate to file+line+col, call fn | inside `condition-case` body |
| `--with-identifier (file id fn)` | Search for id in file, call fn | inside `condition-case` body |
| `--textdoc-position-params ()` | Build LSP TextDocumentPositionParams from current buffer/point | inside `--at-position` lambda |
| `--format-locations (label locs)` | Format `LSP Location[]` → string | inside lambda |
| `--format-xrefs (label xrefs)` | Format `xref-item[]` → string | inside lambda |
| `--eglot-buffer-for-project (file)` | Find a buffer with active eglot in the project | inside Pattern C |

`--at-position` and `--with-identifier` already handle `inhibit-redisplay` and `save-excursion`.

---

## Pattern A — Position-based LSP request

**When**: the tool locates a symbol by file + line + column.

**Examples**: `lsp-find-implementation`, `lsp-find-references`, `lsp-find-typeDefinition`

```elisp
(defun claude-code-ide-mcp-lsp-find-{noun} (file-path line column)
  "Find {noun} at FILE-PATH LINE:COLUMN via eglot textDocument/{Method}."
  (condition-case err
      (claude-code-ide-mcp--at-position
       file-path line column
       (lambda ()
         (let* ((server (eglot-current-server))
                (result (eglot--request server :textDocument/{Method}
                                        (claude-code-ide-mcp--textdoc-position-params)))
                (locations (cond
                            ((null result) nil)
                            ((vectorp result) (append result nil))
                            (t (list result)))))
           (claude-code-ide-mcp--format-locations "{Noun}s" locations))))
    (error (format "Error finding {noun}: %s" (error-message-string err)))))

(claude-code-ide-make-tool
    :function #'claude-code-ide-mcp-lsp-find-{noun}
    :name "claude-code-ide-mcp-lsp-find-{noun}"
    :description "..."
    :args '((:name "file_path" :type string :description "Absolute path to the file")
            (:name "line"      :type number :description "Line number (1-based)")
            (:name "column"    :type number :description "Column number (0-based)")))
```

**LSP methods** for common operations:

| Operation | Method |
|-----------|--------|
| Implementations | `:textDocument/implementation` |
| All references | `:textDocument/references` + `(:context (:includeDeclaration :json-false))` |
| Type definition | `:textDocument/typeDefinition` |

For `:textDocument/references`, append the context param:
```elisp
(eglot--request server :textDocument/references
                (append (claude-code-ide-mcp--textdoc-position-params)
                        '(:context (:includeDeclaration :json-false))))
```

---

## Pattern B — Identifier-based xref tool

**When**: the tool takes a symbol name as a string, no position needed.

**Example**: `lsp-find-definition`

```elisp
(defun claude-code-ide-mcp-lsp-find-{noun} (identifier file-path)
  "Find {noun} of IDENTIFIER in FILE-PATH context."
  (condition-case err
      (claude-code-ide-mcp--with-identifier
       file-path identifier
       (lambda ()
         (claude-code-ide-mcp--format-xrefs
          (format "{Noun}s of '%s'" identifier)
          (xref-backend-{operation} (xref-find-backend) identifier))))
    (error (format "Error finding {noun}: %s" (error-message-string err)))))

(claude-code-ide-make-tool
    :function #'claude-code-ide-mcp-lsp-find-{noun}
    :name "claude-code-ide-mcp-lsp-find-{noun}"
    :description "..."
    :args '((:name "identifier" :type string :description "Symbol name to look up")
            (:name "file_path"  :type string :description "Any file in the project")))
```

---

## Pattern C — Server-context symbol search

**When**: the tool queries the LSP server for symbols across the workspace.

**Examples**: `lsp-workspace-symbols`, `lsp-project-symbols`

```elisp
(defun claude-code-ide-mcp-lsp-{scope}-symbols (query file-path)
  "Search for symbols matching QUERY {scope}-wide via LSP workspace/symbol."
  (condition-case err
      (claude-code-ide-mcp-server-with-session-context nil
        (with-current-buffer (claude-code-ide-mcp--eglot-buffer-for-project file-path)
          (let* ((server (eglot-current-server)))
            (unless server
              (error "No eglot server running in %s" file-path))
            (let* ((result (eglot--request server :workspace/symbol `(:query ,query)))
                   (symbols (if (vectorp result) (append result nil) result)))
              (if (null symbols)
                  (format "No symbols found for query: %s" query)
                (format "Symbols matching '%s' (%d):\n\n%s"
                        query (length symbols)
                        (mapconcat
                         (lambda (sym)
                           (let* ((name  (plist-get sym :name))
                                  (loc   (plist-get sym :location))
                                  (uri   (plist-get loc :uri))
                                  (range (plist-get loc :range))
                                  (line  (1+ (plist-get (plist-get range :start) :line)))
                                  (file  (string-remove-prefix "file://" (url-unhex-string uri))))
                             (format "%s:%d  %s" file line name)))
                         symbols "\n")))))))
    (error (format "Error: %s" (error-message-string err)))))
```

To add project-only filtering (like `lsp-project-symbols`), bind `project-root` in the inner `let*` before `result`:
```elisp
(let* ((project-root
        (when-let* ((proj (project-current nil (file-name-directory
                                                (expand-file-name file-path)))))
          (expand-file-name (project-root proj))))
       (result ...)
       (symbols ...)
       (filtered (seq-filter
                  (lambda (sym)
                    (when-let* ((loc  (plist-get sym :location))
                                (uri  (plist-get loc :uri))
                                (file (string-remove-prefix "file://" (url-unhex-string uri))))
                      (and project-root (string-prefix-p project-root file))))
                  symbols)))
  ...)
```

### CRITICAL — condition-case placement for Pattern C

`claude-code-ide-mcp-server-with-session-context` is a macro that splices `,@body` in two places. The `(error ...)` handler of `condition-case` must close at the same nesting level as `condition-case`, NOT inside the macro body.

**After writing, always run the Step 4.5 diagnostic** (see `elisp.md`):
```
Expected: (handler-conditions (claude-code-ide-mcp-server-with-session-context error))
Bug:      (handler-conditions (claude-code-ide-mcp-server-with-session-context))
```

Count closing parens at the end of the macro body: the last `)` of the macro call must appear on the `mapconcat`/format line, not on the `(error ...)` handler line.

```elisp
;; Correct — macro call closes on the format line (one extra `)`)
                         symbols "\n")))))))     ; closes: mapconcat format if let*(inner) let*(server) with-current-buffer macro-call
    (error (format "Error: ..." err)))))         ; closes: error-msg format handler condition-case defun

;; Bug — macro call absorbs the handler
                         symbols "\n"))))))      ; closes only 6 — macro still open
    (error (format "Error: ..." err))))))        ; 4th `)` closes macro; condition-case has no handler
```

---

## After adding a tool

1. Run Step 4.5 diagnostic if the tool uses Pattern C.
2. Verify total tool count matches `max_results` in `SKILL.md`:
   ```elisp
   (length (seq-filter (lambda (t) (string-prefix-p "claude-code-ide-mcp-"
                                                     (plist-get t :name)))
                       claude-code-ide-mcp-server-tools))
   ```
3. Add the tool to the navigation table in `navigation.md`.
4. Load the file: `elisp-load-file`.