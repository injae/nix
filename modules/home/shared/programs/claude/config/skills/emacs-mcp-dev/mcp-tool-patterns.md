# MCP Tool Patterns — LSP Navigation

Use when add tool to `extras/claude-code-ide-extra-lsp-nav-position.el` (Pattern A, B) or `extras/claude-code-ide-extra-lsp-nav-workspace.el` (Pattern C).
General MCP tool rule (naming, registration, inhibit-redisplay): see `emacs-mcp-dev` skill.

---

## Helper overview

Helper live in two `lsp-nav` extras file. Build block for all pattern below.

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

**When**: tool find symbol by file + line + column.

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

**LSP methods** for common op:

| Operation | Method |
|-----------|--------|
| Implementations | `:textDocument/implementation` |
| All references | `:textDocument/references` + `(:context (:includeDeclaration :json-false))` |
| Type definition | `:textDocument/typeDefinition` |

For `:textDocument/references`, add context param:
```elisp
(eglot--request server :textDocument/references
                (append (claude-code-ide-mcp--textdoc-position-params)
                        '(:context (:includeDeclaration :json-false))))
```

---

## Pattern B — Identifier-based xref tool

**When**: tool take symbol name as string. No position need.

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

**When**: tool ask LSP server for symbol across workspace.

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

For project-only filter (like `lsp-project-symbols`), bind `project-root` in inner `let*` before `result`:
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

`claude-code-ide-mcp-server-with-session-context` is macro. It splice `,@body` in two place. `(error ...)` handler of `condition-case` must close at same nesting level as `condition-case`, NOT inside macro body.

**After write, always run Step 4.5 diagnostic:**
```
Expected: (handler-conditions (claude-code-ide-mcp-server-with-session-context error))
Bug:      (handler-conditions (claude-code-ide-mcp-server-with-session-context))
```

Count close paren at end of macro body: last `)` of macro call must sit on `mapconcat`/format line, not on `(error ...)` handler line.

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

1. Run Step 4.5 diagnostic if tool use Pattern C.
2. Check tool count stay under `max_results` in `emacs-dev/SKILL.md`:
   ```elisp
   (length claude-code-ide-mcp-server-tools)
   ```
3. Add tool to navigation table in `emacs-navigation` skill (`emacs-navigation/SKILL.md`).
4. Add it to `tools:` allowlist of every agent that must reach it —
   `agents/Explore.md`, `agents/fable-review.md`, `agents/codex-review.md`.
   List is explicit: tool missing from one is invisible to that agent.
5. Load file: `elisp-load`, then `claude-code-ide-reload-mcp-tools` to
   re-register. New `:name` reach CLI only in new session.