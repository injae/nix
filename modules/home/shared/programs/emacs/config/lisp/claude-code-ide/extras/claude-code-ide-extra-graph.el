;;; claude-code-ide-extra-graph.el --- MCP tools: call graph -*- lexical-binding: t; -*-
;;; Commentary:
;; symbol-graph: recursive caller/callee graph.  Servers advertising
;; callHierarchyProvider get a real multi-level walk; the rest fall back to a
;; depth-1 report built from textDocument/references, then from text search.
;;; Code:

(require 'claude-code-ide-mcp-server)
(require 'claude-code-ide-extra-lsp-nav-position)
(require 'claude-code-ide-extra-lsp-nav-workspace)
(require 'claude-code-ide-extra-buffer-info)
(require 'claude-code-ide-extra-search)

(defun claude-code-ide-mcp--graph-direction (direction)
  "Normalize DIRECTION to `callers', `callees' or `both'."
  (cond ((member direction '("callees" "callee")) 'callees)
        ((equal direction "both") 'both)
        (t 'callers)))

(defun claude-code-ide-mcp--graph-item-node (item)
  "Build a graph node from CallHierarchyItem ITEM, or nil when unusable.
An item without a uri or a range cannot be placed, and signalling here would
replace the whole graph with an error string."
  (let* ((uri (plist-get item :uri))
         (range (or (plist-get item :selectionRange) (plist-get item :range)))
         (line (plist-get (plist-get range :start) :line)))
    (when (and uri line)
      (list :name (or (plist-get item :name) "?")
            :file (string-remove-prefix "file://" (url-unhex-string uri))
            :line (1+ line)
            :item item))))

(defun claude-code-ide-mcp--graph-request (server method params)
  "Send METHOD with PARAMS to SERVER, returning nil instead of signalling.
Multiplexing servers advertise callHierarchyProvider yet answer the
callHierarchy methods with -32601, so a failed request must degrade."
  (condition-case nil
      (eglot--request server method params :timeout 10)
    (jsonrpc-error nil)))

(defun claude-code-ide-mcp--graph-step (server item direction)
  "Return neighbour nodes of ITEM in DIRECTION, asking SERVER."
  (let* ((method (if (eq direction 'callees)
                     :callHierarchy/outgoingCalls
                   :callHierarchy/incomingCalls))
         (key (if (eq direction 'callees) :to :from))
         (raw (claude-code-ide-mcp--graph-request server method `(:item ,item)))
         (calls (cond ((vectorp raw) (append raw nil))
                      ((listp raw) raw))))
    (delq nil
          (mapcar (lambda (call)
                    (claude-code-ide-mcp--graph-item-node (plist-get call key)))
                  calls))))

(defun claude-code-ide-mcp--graph-lines (ctx dir node depth level)
  "Render NODE's subtree in DIR under CTX, descending DEPTH levels at LEVEL.
CTX is a plist of :server :cap :visited :counter :include-source and :base."
  (let* ((visited (plist-get ctx :visited))
         (counter (plist-get ctx :counter))
         (cap (plist-get ctx :cap))
         (file (plist-get node :file))
         (line (plist-get node :line))
         (key (cons file line)))
    (setcar counter (1+ (car counter)))
    (unless (and (> cap 0) (> (car counter) cap))
      (let ((label (format "%s%s  %s:%d"
                           (make-string (* 2 level) ?\s)
                           (plist-get node :name)
                           (file-relative-name file (plist-get ctx :base))
                           line)))
        (if (gethash key visited)
            (list (concat label "  (seen)"))
          (puthash key t visited)
          (cons (if (claude-code-ide-mcp--flag-set-p (plist-get ctx :include-source))
                    (concat label "\n" (claude-code-ide-mcp-symbol-source file line))
                  label)
                (when (> depth 0)
                  (mapcan
                   (lambda (n)
                     (claude-code-ide-mcp--graph-lines ctx dir n (1- depth) (1+ level)))
                   (claude-code-ide-mcp--graph-step
                    (plist-get ctx :server)
                    (plist-get node :item)
                    dir)))))))))

(defun claude-code-ide-mcp--graph-one-direction (base-ctx dir node identifier depth)
  "Render NODE's graph in DIR for IDENTIFIER, DEPTH levels deep, under BASE-CTX.
BASE-CTX carries :server :cap :counter :include-source and :base.  A fresh
visited table is added here, so a node reached in one direction is not
reported as already seen in the other; the node counter is shared, so CAP
bounds the whole call rather than each direction."
  (let* ((ctx (append (list :visited (make-hash-table :test 'equal)) base-ctx))
         (cap (plist-get ctx :cap))
         (counter (plist-get ctx :counter))
         (lines (claude-code-ide-mcp--graph-lines ctx dir node depth 0)))
    (concat (format "%s of '%s' (depth %d):\n"
                    (if (eq dir 'callees) "Callees" "Callers") identifier depth)
            (string-join lines "\n")
            (when (and (> cap 0) (> (car counter) cap))
              (format "\n... truncated at cap %d; raise cap to see more" cap)))))

(defun claude-code-ide-mcp--graph-hierarchy (identifier root direction depth cap include-source)
  "Render the callHierarchy graph for IDENTIFIER at point, or nil.
Returns nil when the server cannot prepare a usable call hierarchy here, so
the caller can degrade.  ROOT is the base for relative paths; DIRECTION,
DEPTH, CAP and INCLUDE-SOURCE come from the tool arguments."
  (let* ((raw (claude-code-ide-mcp--graph-request
               (eglot-current-server)
               :textDocument/prepareCallHierarchy
               (claude-code-ide-mcp--textdoc-position-params)))
         (items (cond ((vectorp raw) (append raw nil))
                      ((null raw) nil)
                      (t (list raw))))
         (node (and items (claude-code-ide-mcp--graph-item-node (car items)))))
    (when node
      (let ((base-ctx (list :server (eglot-current-server)
                            :cap cap
                            :counter (list 0)
                            :include-source include-source
                            :base root)))
        (concat
         (when (> (length items) 1)
           (format "%d call-hierarchy candidates for '%s'; walking the first\n\n"
                   (length items) identifier))
         (mapconcat
          (lambda (dir)
            (claude-code-ide-mcp--graph-one-direction
             base-ctx dir node identifier depth))
          (if (eq direction 'both) '(callers callees) (list direction))
          "\n\n"))))))

(defun claude-code-ide-mcp--graph-loc-cell (loc)
  "Return a (FILE . LINE) cell for LSP Location or LocationLink LOC, or nil.
Servers may answer references with either shape, and terraform-ls answers
with entries carrying no range at all."
  (let* ((uri (or (plist-get loc :uri) (plist-get loc :targetUri)))
         (range (or (plist-get loc :range)
                    (plist-get loc :targetSelectionRange)
                    (plist-get loc :targetRange)))
         (line (plist-get (plist-get range :start) :line)))
    (when (and uri line)
      (cons (string-remove-prefix "file://" (url-unhex-string uri))
            (1+ line)))))

(defun claude-code-ide-mcp--graph-ref-cells ()
  "Return (FILE . LINE) cells for textDocument/references at point."
  (let* ((raw (claude-code-ide-mcp--graph-request
               (eglot-current-server)
               :textDocument/references
               (append (claude-code-ide-mcp--textdoc-position-params)
                       '(:context (:includeDeclaration :json-false)))))
         (locations (cond ((null raw) nil)
                          ((vectorp raw) (append raw nil))
                          (t (list raw)))))
    (delq nil (mapcar #'claude-code-ide-mcp--graph-loc-cell locations))))

(defun claude-code-ide-mcp--graph-block-report (identifier root recs note cap)
  "Format block records RECS as a depth-1 caller report for IDENTIFIER.
ROOT is the base for relative paths, NOTE explains how RECS were obtained and
CAP limits how many blocks are rendered."
  (if (null recs)
      (format "No callers found for '%s' under %s." identifier root)
    (format "Callers of '%s' (%s; %d blocks):\n\n%s"
            identifier note (length recs)
            (claude-code-ide-mcp--text-refs-render recs root cap))))

(defun claude-code-ide-mcp--graph-text-report (identifier root cap note)
  "Depth-1 caller report for IDENTIFIER from text search under ROOT.
CAP limits files and blocks; NOTE says why this path was taken.  Needs no
language server, so it is the answer of last resort."
  (let ((found (claude-code-ide-mcp--identifier-text-refs identifier root cap)))
    (concat (claude-code-ide-mcp--graph-block-report
             identifier root (car found) note cap)
            (claude-code-ide-mcp--text-refs-omitted-note (cdr found)))))

(defun claude-code-ide-mcp--graph-shallow (identifier root direction cap)
  "Depth-1 caller report for IDENTIFIER at point, relative to ROOT.
CAP limits both the files inspected and the blocks rendered.  Used when
callHierarchy is unavailable, so DIRECTION `callees' cannot be served."
  (if (eq direction 'callees)
      (format "callHierarchy is unavailable here, so callees of '%s' cannot be resolved. Ask for callers instead." identifier)
    (let* ((cells (claude-code-ide-mcp--graph-ref-cells))
           (semantic (and cells
                          (claude-code-ide-mcp--grep-block-collect
                           (car (claude-code-ide-mcp--limit-matches-by-file cells cap)))))
           (report
            (if semantic
                (claude-code-ide-mcp--graph-block-report
                 identifier root semantic "depth 1, callHierarchy unavailable" cap)
              (claude-code-ide-mcp--graph-text-report
               identifier root cap
               "textual fallback, depth 1, callHierarchy unavailable"))))
      (if (eq direction 'both)
          (concat report "\n\nCallees unavailable: callHierarchy is not served here.")
        report))))

(defun claude-code-ide-mcp-symbol-graph (identifier file-path &optional direction depth cap include-source)
  "Return the call graph around IDENTIFIER, resolved from FILE-PATH's project.
DIRECTION is \"callers\" (default), \"callees\" or \"both\".  DEPTH bounds the
walk (default 2) and CAP the node count (default 40, 0 = unlimited).
INCLUDE-SOURCE adds each node's definition source.  Every language-server
step degrades rather than failing: no server, no definition, or a rejected
request each fall through to the text-search report."
  (condition-case err
      (let* ((direction (claude-code-ide-mcp--graph-direction direction))
             (depth (if (numberp depth) depth 2))
             (cap (if (numberp cap) cap 40))
             (root (claude-code-ide-mcp--project-root-for file-path))
             (def (ignore-errors
                    (claude-code-ide-mcp--resolve-symbol-location identifier file-path))))
        (if (null def)
            (claude-code-ide-mcp--graph-text-report
             identifier root cap "textual fallback, depth 1, no definition resolved")
          (or (ignore-errors
                (claude-code-ide-mcp--at-position
                 (plist-get def :file)
                 (plist-get def :line)
                 (plist-get def :col)
                 (lambda ()
                   (or (and (eglot-server-capable :callHierarchyProvider)
                            (claude-code-ide-mcp--graph-hierarchy
                             identifier root direction depth cap include-source))
                       (claude-code-ide-mcp--graph-shallow identifier root direction cap)))))
              (claude-code-ide-mcp--graph-text-report
               identifier root cap "textual fallback, depth 1, LSP request failed"))))
    (error (format "Error building graph: %s" (error-message-string err)))))

(claude-code-ide-make-tool
    :function #'claude-code-ide-mcp-symbol-graph
    :name "symbol-graph"
    :description "Recursive caller/callee graph for a symbol, one call. Each node is name + file:line, indented by depth; a node already shown in the same direction is marked (seen). Servers serving callHierarchy get a real multi-level walk; every other outcome degrades instead of failing -- no server, no definition, or a rejected request each fall through to a depth-1 caller report, whose lines carry the enclosing declaration and which cannot answer callees. Output always names which path produced it. Args: identifier, file_path (any project file), direction (callers default | callees | both), depth (default 2), cap (max nodes for the whole call, shared across directions, default 40, 0=unlimited), include_source (non-empty adds each node's definition source; with depth 1 that gives a definition plus every call site in one response)."
    :args '((:name "identifier"
             :type string
             :description "Exact symbol name")
            (:name "file_path"
             :type string
             :description "Any project file (finds eglot server and root)")
            (:name "direction"
             :type string
             :description "callers (default) | callees | both"
             :optional t)
            (:name "depth"
             :type number
             :description "Levels to walk; default 2"
             :optional t)
            (:name "cap"
             :type number
             :description "Max nodes; default 40, 0=unlimited"
             :optional t)
            (:name "include_source"
             :type string
             :description "Non-empty = add each node's definition source"
             :optional t)))

(provide 'claude-code-ide-extra-graph)
;;; claude-code-ide-extra-graph.el ends here
