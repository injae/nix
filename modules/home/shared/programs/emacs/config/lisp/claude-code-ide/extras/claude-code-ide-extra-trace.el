;;; claude-code-ide-extra-trace.el --- MCP tools: exploration graph -*- lexical-binding: t; -*-
;;; Commentary:
;; trace: seed a search, turn each hit into a graph node carrying a normalized
;; content hash, append the new nodes to a per-project JSONL store, and answer
;; the clone query in the same call.  The store admits only nodes, edges,
;; evidence kinds, queries and hashes -- never free prose, so every claim in it
;; stays re-runnable.
;;; Code:

(require 'cl-lib)
(require 'subr-x)
(require 'treesit nil t)
(require 'project)
(require 'eglot)
(require 'claude-code-ide-mcp-server)
(require 'claude-code-ide-extra-search)
(require 'claude-code-ide-extra-lsp-nav-position)

(defconst claude-code-ide-mcp--trace-block-cap 200
  "Default maximum number of blocks a single trace turns into nodes.")

(defconst claude-code-ide-mcp--trace-file-cap 100
  "Default maximum number of distinct files a single trace visits.
The collector holds one buffer per file, so an uncapped seed would exhaust
the file descriptors of the whole Emacs session.  A question that has to be
answered in full raises this through the tool's own argument, since a capped
answer is not the whole answer even when the report says which files it left.")

(defconst claude-code-ide-mcp--trace-hash-length 12
  "Number of leading hex characters kept from a node's content hash.")

(defun claude-code-ide-mcp--trace-project-root (search-root)
  "Return the project root containing SEARCH-ROOT, else its own directory.
Node ids and the store are keyed on the project, never on the directory a
caller happened to search: the same block reached through \"src\" and through
the repository root has to come out as one node, not two."
  (let ((dir (if (file-directory-p search-root)
                 (file-name-as-directory (expand-file-name search-root))
               (file-name-directory (expand-file-name search-root)))))
    (or (when-let* ((proj (ignore-errors (project-current nil dir))))
          (expand-file-name (project-root proj)))
        dir)))

(defun claude-code-ide-mcp--trace-store-file (root)
  "Return the JSONL graph store belonging to project ROOT.
The store lives outside the project so it cannot be mistaken for
documentation the way a checked-in map would be."
  (expand-file-name
   "graph.jsonl"
   (expand-file-name
    (replace-regexp-in-string "[/.]" "-"
                              (directory-file-name (expand-file-name root)))
    (expand-file-name "projects" (expand-file-name "~/.claude")))))

(defun claude-code-ide-mcp--trace-known (store)
  "Return what STORE already holds, read in the order it was written.
The plist carries :nodes id to hash, :node-files and :node-queries beside it,
:edges by identity, :queries in the order they were asked, and :scan, the
last look at the tree.  A `gone' record removes the node it names, which is
why the file is replayed rather than scanned for the newest line per id."
  (let ((nodes (make-hash-table :test 'equal))
        (node-files (make-hash-table :test 'equal))
        (node-lines (make-hash-table :test 'equal))
        (node-uses (make-hash-table :test 'equal))
        (node-queries (make-hash-table :test 'equal))
        (edges (make-hash-table :test 'equal))
        (edge-list '())
        (files (make-hash-table :test 'equal))
        (file-imports (make-hash-table :test 'equal))
        (queries '())
        (absent '())
        (scan nil))
    (when (file-readable-p store)
      (with-temp-buffer
        (insert-file-contents store)
        (goto-char (point-min))
        (while (not (eobp))
          (let ((line (buffer-substring-no-properties
                       (line-beginning-position) (line-end-position))))
            (unless (string-empty-p line)
              (let* ((rec (ignore-errors
                            (json-parse-string line :object-type 'plist)))
                     (kind (plist-get rec :k))
                     (id (plist-get rec :id)))
                (cond
                 ((equal kind "node")
                  (puthash id (plist-get rec :hash) nodes)
                  (puthash id (plist-get rec :file) node-files)
                  (puthash id (plist-get rec :line) node-lines)
                  (puthash id (plist-get rec :uses) node-uses)
                  (puthash id (plist-get rec :q) node-queries))
                 ((equal kind "gone")
                  (remhash id nodes)
                  (remhash id node-files)
                  (remhash id node-lines)
                  (remhash id node-uses)
                  (remhash id node-queries))
                 ((equal kind "edge")
                  (unless (gethash (claude-code-ide-mcp--trace-edge-key rec) edges)
                    (push rec edge-list))
                  (puthash (claude-code-ide-mcp--trace-edge-key rec) t edges))
                 ((equal kind "absent") (push rec absent))
                 ((equal kind "query") (push rec queries))
                 ((equal kind "file")
                  (puthash (plist-get rec :path) (plist-get rec :hash) files)
                  (puthash (plist-get rec :path) (plist-get rec :imports)
                           file-imports))
                 ((equal kind "scan") (setq scan rec))))))
          (forward-line 1))))
    (list :nodes nodes
          :node-files node-files
          :node-lines node-lines
          :node-uses node-uses
          :node-queries node-queries
          :edges edges
          :edge-list (nreverse edge-list)
          :files files
          :file-imports file-imports
          :queries (nreverse queries)
          :absent (nreverse absent)
          :scan scan)))

(defun claude-code-ide-mcp--trace-file-hash (file)
  "Return the hash of FILE's bytes, or nil when it cannot be read."
  (when (file-readable-p file)
    (with-temp-buffer
      (set-buffer-multibyte nil)
      (insert-file-contents-literally file)
      (claude-code-ide-mcp--trace-hash (buffer-string)))))

(defun claude-code-ide-mcp--trace-append (store records)
  "Append RECORDS, one JSON object per line, to STORE."
  (make-directory (file-name-directory store) t)
  (with-temp-buffer
    (dolist (rec records)
      (insert (json-serialize rec) "\n"))
    (write-region (point-min) (point-max) store t 'silent)))

(defun claude-code-ide-mcp--trace-node-name (node)
  "Return the name NODE declares, or nil when it declares none.
The mode is asked first, since it knows its own grammar; the field lookup
behind it covers the nodes a mode does not count as declarations at all, such
as the modules a symbol path still has to name.  An impl block names itself
through its `type' field rather than a `name' field."
  (or (ignore-errors (treesit-defun-name node))
      (when-let* ((field (if (string-match-p "impl" (treesit-node-type node))
                             (treesit-node-child-by-field-name node "type")
                           (treesit-node-child-by-field-name node "name"))))
        (treesit-node-text field t))))

(defun claude-code-ide-mcp--trace-symbol-path (node)
  "Return NODE's declaration path, its named ancestors joined by \"::\".
Line numbers are deliberately absent: they move under every edit, and a node
identity that moves cannot be compared across two traces."
  (let ((parts '())
        (cur node))
    (while cur
      (when-let* ((name (claude-code-ide-mcp--trace-node-name cur)))
        (push name parts))
      (setq cur (treesit-node-parent cur)))
    (string-join parts "::")))

(defun claude-code-ide-mcp--trace-normalized-text (node)
  "Return NODE's token text with comments dropped and whitespace collapsed."
  (let ((parts '()))
    (cl-labels
        ((walk (n)
           (unless (string-match-p "comment" (treesit-node-type n))
             (let ((count (treesit-node-child-count n)))
               (if (zerop count)
                   (push (treesit-node-text n t) parts)
                 (dotimes (i count)
                   (walk (treesit-node-child n i))))))))
      (walk node))
    (string-join (nreverse parts) " ")))

(defun claude-code-ide-mcp--trace-hash (text)
  "Return the truncated SHA-256 of TEXT."
  (substring (secure-hash 'sha256 text) 0 claude-code-ide-mcp--trace-hash-length))

(defun claude-code-ide-mcp--trace-block-node (line)
  "Return the tightest enclosing named multi-line node at LINE, or nil.
Comment nodes are refused: a comment that spans lines would otherwise become
the block of every hit inside it, and normalization empties them all to the
same hash."
  (save-excursion
    (goto-char (point-min))
    (forward-line (1- line))
    (back-to-indentation)
    (when-let* ((node (and (fboundp 'treesit-node-at)
                           (treesit-parser-list)
                           (treesit-node-at (point)))))
      (treesit-parent-until
       node
       (lambda (n)
         (and (treesit-node-check n 'named)
              (treesit-node-parent n)
              (not (string-match-p "comment" (treesit-node-type n)))
              (> (line-number-at-pos (treesit-node-end n))
                 (line-number-at-pos (treesit-node-start n)))))
       t))))

(defun claude-code-ide-mcp--trace-declaration (node)
  "Return NODE, or its nearest ancestor, that declares a name.  Nil when none."
  (let ((cur node))
    (while (and cur (null (claude-code-ide-mcp--trace-node-name cur)))
      (setq cur (treesit-node-parent cur)))
    cur))

(defun claude-code-ide-mcp--trace-child-index (node)
  "Return NODE's index among its parent's children, or nil when it has none."
  (when-let* ((parent (treesit-node-parent node)))
    (let ((count (treesit-node-child-count parent))
          (i 0)
          (found nil))
      (while (and (< i count) (null found))
        (when (treesit-node-eq (treesit-node-child parent i) node)
          (setq found i))
        (setq i (1+ i)))
      found)))

(defun claude-code-ide-mcp--trace-inner-path (node decl)
  "Return NODE's child-index path below DECL, dot-joined, empty when equal.
A declaration holds many blocks, and the duplicated idioms this tool looks
for live in those blocks rather than in the declaration itself, so the
declaration path alone cannot tell two of them apart."
  (let ((parts '())
        (cur node))
    (while (and cur (not (and decl (treesit-node-eq cur decl))))
      (push (number-to-string (or (claude-code-ide-mcp--trace-child-index cur) 0))
            parts)
      (setq cur (treesit-node-parent cur)))
    (string-join parts ".")))

(defun claude-code-ide-mcp--trace-node-record (file root node query-id text
                                                    &optional imports)
  "Return the store record describing NODE of FILE, relative to ROOT.
TEXT is NODE's normalized text, QUERY-ID names the query that found it, and
IMPORTS are the names this file brings into scope, of which the record keeps
the ones NODE actually mentions."
  (let* ((rel (file-relative-name file root))
         (decl (claude-code-ide-mcp--trace-declaration node))
         (path (if decl (claude-code-ide-mcp--trace-symbol-path decl) ""))
         (inner (claude-code-ide-mcp--trace-inner-path node decl))
         (base (if (string-empty-p path) rel (concat rel "::" path))))
    (list :k "node"
          :id (if (string-empty-p inner)
                  base
                (format "%s@%s:%s" base (treesit-node-type node) inner))
          :file rel
          ;; A locator, never an identity: it is not in the id, not in the
          ;; hash, and not compared.  Lines move for reasons the hash cannot
          ;; see -- a comment added above shifts them all -- so it is
          ;; rewritten on every trace and read only to open the file.
          :line (line-number-at-pos (treesit-node-start node))
          :kind (treesit-node-type node)
          :hash (claude-code-ide-mcp--trace-hash text)
          :uses (vconcat (claude-code-ide-mcp--trace-uses node imports))
          :ev "treesit"
          :q query-id)))

(defvar claude-code-ide-mcp-trace-language-rules
  '((rust-ts-mode
     :register (("add_systems" . 1) ("add_plugins" . 0))
     :attributes (("require" . "requires"))
     :imports "use_declaration"))
  "Per-language knowledge no grammar carries, keyed by major mode.

`:register' lists the methods whose arguments register the things they name,
each paired with how many leading arguments come before those names.
`:attributes' maps an attribute's own name to the edge kind it declares.
`:imports' is the node type an import declaration has, which decides what a
name in this file resolves against.

Everything else about edge extraction is read from the mode's own tree-sitter
settings, so a mode absent from this list still yields call and ordering
edges -- only the two kinds above need telling.")

(defconst claude-code-ide-mcp--trace-lsp-file-cap 60
  "Maximum number of files a single trace puts under a language server.
Resolving an endpoint needs the referring file managed by eglot, which costs
about three times a plain visit, and the whole call blocks Emacs meanwhile.")

(defconst claude-code-ide-mcp--trace-call-search-depth 3
  "How far above a called name the call expression may sit.")

(defun claude-code-ide-mcp--trace-rules ()
  "Return the language rules for the current buffer's mode."
  (alist-get major-mode claude-code-ide-mcp-trace-language-rules))

(defun claude-code-ide-mcp--trace-feature-nodes (feature beg end)
  "Return the nodes FEATURE's own font-lock query captures between BEG and END.
Font-lock feature names are shared across tree-sitter modes, so asking the
mode which tokens are calls, types or attributes routes the search without
this file naming any grammar's node types.  The region is applied again here
because `treesit-query-capture' bounds which patterns it tries, not which
captures come back, and a chain of calls needs each link read on its own."
  (let ((out '()))
    (dolist (setting treesit-font-lock-settings)
      (when (eq (nth 2 setting) feature)
        (dolist (capture (ignore-errors
                           (treesit-query-capture
                            (treesit-buffer-root-node) (nth 0 setting) beg end)))
          (let ((node (cdr capture)))
            (when (and (>= (treesit-node-start node) beg)
                       (<= (treesit-node-end node) end))
              (push node out))))))
    (sort out (lambda (a b) (< (treesit-node-start a) (treesit-node-start b))))))

(defun claude-code-ide-mcp--trace-name-node-p (node)
  "Non-nil when NODE reads as a plain name rather than a compound expression."
  (and node
       (treesit-node-check node 'named)
       (string-match-p
        "\\`[A-Za-z_][A-Za-z0-9_]*\\(?:\\(?:::\\|\\.\\)[A-Za-z_][A-Za-z0-9_]*\\)*\\'"
        (treesit-node-text node t))))

(defun claude-code-ide-mcp--trace-named-children (node)
  "Return NODE's named children as a list, or nil when NODE is nil."
  (when node
    (let ((out '()))
      (dotimes (i (treesit-node-child-count node t))
        (push (treesit-node-child node i t) out))
      (nreverse out))))

(defun claude-code-ide-mcp--trace-names-in (node)
  "Return the plain name nodes below NODE, in source order."
  (let ((out '()))
    (cl-labels
        ((walk (n)
           (if (claude-code-ide-mcp--trace-name-node-p n)
               (push n out)
             (dotimes (i (treesit-node-child-count n t))
               (walk (treesit-node-child n i t))))))
      (walk node))
    (nreverse out)))

(defun claude-code-ide-mcp--trace-ref (node)
  "Return an endpoint plist naming NODE's text and where it sits."
  (list :name (treesit-node-text node t)
        :file (buffer-file-name)
        :line (line-number-at-pos (treesit-node-start node))
        :col (save-excursion
               (goto-char (treesit-node-start node))
               (current-column))))

(defun claude-code-ide-mcp--trace-import-nodes ()
  "Return the current buffer's import declarations, or nil when unknown here.
Which node an import is cannot be read off the grammar the way a call can --
no font-lock feature marks one -- so the language rules name it."
  (when-let* ((type (plist-get (claude-code-ide-mcp--trace-rules) :imports))
              (root (and (treesit-parser-list) (treesit-buffer-root-node))))
    (let ((out '()))
      (cl-labels
          ((walk (n)
             (if (string-match-p type (treesit-node-type n))
                 (push n out)
               (dotimes (i (treesit-node-child-count n t))
                 (walk (treesit-node-child n i t))))))
        (walk root))
      (nreverse out))))

(defun claude-code-ide-mcp--trace-import-names ()
  "Return the names the current buffer's imports bring into scope."
  (delete-dups
   (mapcar (lambda (n) (treesit-node-text n t))
           (mapcan #'claude-code-ide-mcp--trace-names-in
                   (claude-code-ide-mcp--trace-import-nodes)))))

(defun claude-code-ide-mcp--trace-uses (node names)
  "Return the members of NAMES that NODE's own tokens mention.
This is what makes an import change readable at node level: when an import
moves, only the nodes that name it are worth re-reading, and a file-wide
flag would light up every node in the file instead."
  (when names
    (let ((tokens (make-hash-table :test 'equal)))
      (dolist (token (split-string (claude-code-ide-mcp--trace-normalized-text node)
                                   " " t))
        (puthash token t tokens))
      (seq-filter (lambda (name)
                    (or (gethash name tokens)
                        (seq-some (lambda (part) (gethash part tokens))
                                  (split-string name "::" t))))
                  names))))

(defun claude-code-ide-mcp--trace-changed-imports (files known)
  "Return a table of path to the import names that moved, given FILES and KNOWN.
FILES are this run's file records; KNOWN holds what the store last saw."
  (let ((table (make-hash-table :test 'equal)))
    (dolist (rec files)
      (let* ((path (plist-get rec :path))
             (now (append (plist-get rec :imports) nil))
             (before (append (gethash path (plist-get known :file-imports)) nil)))
        (when before
          (let ((moved (append (seq-difference now before)
                               (seq-difference before now))))
            (when moved (puthash path moved table))))))
    table))

(defun claude-code-ide-mcp--trace-covers-p (outer inner)
  "Non-nil when OUTER spans INNER."
  (and outer inner
       (<= (treesit-node-start outer) (treesit-node-start inner))
       (>= (treesit-node-end outer) (treesit-node-end inner))))

(defun claude-code-ide-mcp--trace-call-of (name)
  "Return the call whose called name is NAME, or nil.
The call is the nearest ancestor holding an argument list whose callee part
still spans NAME, which is how a grammar spells a call whatever it calls its
nodes."
  (let ((cur (treesit-node-parent name))
        (depth 0)
        (found nil))
    (while (and cur (null found) (< depth claude-code-ide-mcp--trace-call-search-depth))
      (when (and (treesit-node-child-by-field-name cur "arguments")
                 (claude-code-ide-mcp--trace-covers-p
                  (treesit-node-child-by-field-name cur "function") name))
        (setq found cur))
      (setq cur (treesit-node-parent cur))
      (setq depth (1+ depth)))
    found))

(defun claude-code-ide-mcp--trace-callee-name (call)
  "Return the name CALL calls, as the mode's own font-lock query marks it.
Reading the callee off the text instead would take `app.add_systems' for one
name, since a member access and a scoped name are spelled alike."
  (when-let* ((fn (treesit-node-child-by-field-name call "function")))
    (car (last (claude-code-ide-mcp--trace-feature-nodes
                'function (treesit-node-start fn) (treesit-node-end fn))))))

(defun claude-code-ide-mcp--trace-receiver (call)
  "Return what CALL is called on, or nil when it is called on nothing."
  (when-let* ((fn (treesit-node-child-by-field-name call "function"))
              (name (claude-code-ide-mcp--trace-callee-name call)))
    (unless (treesit-node-eq fn name)
      (treesit-node-child fn 0 t))))

(defun claude-code-ide-mcp--trace-arg-names (call)
  "Return the plain names CALL is given as arguments."
  (seq-filter #'claude-code-ide-mcp--trace-name-node-p
              (claude-code-ide-mcp--trace-named-children
               (treesit-node-child-by-field-name call "arguments"))))

(defun claude-code-ide-mcp--trace-peel (expr box)
  "Return the base names of EXPR, collecting the edges wrapped around them.
A registered thing arrives inside its own ordering calls -- `X.after(Y)
.in_set(Z)' -- and every wrap is itself an edge, so peeling down to X yields
those edges on the way.  BOX is a one-element list used as an accumulator."
  (cond
   ((null expr) nil)
   ((claude-code-ide-mcp--trace-name-node-p expr) (list expr))
   ((treesit-node-child-by-field-name expr "arguments")
    (when-let* ((receiver (claude-code-ide-mcp--trace-receiver expr))
                (method (claude-code-ide-mcp--trace-callee-name expr)))
      (let ((base (claude-code-ide-mcp--trace-peel receiver box))
            (targets (claude-code-ide-mcp--trace-arg-names expr))
            (kind (treesit-node-text method t)))
        (dolist (from base)
          (dolist (to targets)
            (push (list :kind kind
                        :from (claude-code-ide-mcp--trace-ref from)
                        :to (claude-code-ide-mcp--trace-ref to))
                  (car box))))
        base)))
   (t
    ;; A group of registered things peels member by member; anything else --
    ;; a closure, a literal, a macro -- registers nothing this can name, and
    ;; mining it for identifiers would report its locals as systems.
    (let* ((children (claude-code-ide-mcp--trace-named-children expr))
           (peeled (and children
                        (mapcar (lambda (child)
                                  (claude-code-ide-mcp--trace-peel child box))
                                children))))
      (when (and peeled (not (memq nil peeled)))
        (apply #'append peeled))))))

(defun claude-code-ide-mcp--trace-register-edges (call from-id box)
  "Collect what CALL registers, sourced at FROM-ID, into BOX.
Returns non-nil when CALL was a registering call."
  (when-let* ((method (claude-code-ide-mcp--trace-callee-name call))
              (entry (assoc (treesit-node-text method t)
                            (plist-get (claude-code-ide-mcp--trace-rules) :register))))
    (let* ((args (claude-code-ide-mcp--trace-named-children
                  (treesit-node-child-by-field-name call "arguments")))
           (registered (nthcdr (cdr entry) args)))
      (dolist (arg registered)
        (dolist (base (claude-code-ide-mcp--trace-peel arg box))
          (push (list :kind "registers"
                      :from (list :id from-id)
                      :to (claude-code-ide-mcp--trace-ref base))
                (car box))))
      t)))

(defun claude-code-ide-mcp--trace-declaration-p (node)
  "Non-nil when NODE is what this mode calls a declaration."
  (and node treesit-defun-type-regexp
       (string-match-p treesit-defun-type-regexp (treesit-node-type node))))

(defun claude-code-ide-mcp--trace-attribute-owner (item)
  "Return the declaration ITEM speaks for.
An attribute either wraps its declaration or precedes it, and which one is a
property of the grammar, so the answer is read off the tree rather than
configured."
  (let ((parent (treesit-node-parent item)))
    (if (claude-code-ide-mcp--trace-declaration-p parent)
        parent
      (let ((cur (treesit-node-next-sibling item t)))
        (while (and cur (not (claude-code-ide-mcp--trace-declaration-p cur)))
          (setq cur (treesit-node-next-sibling cur t)))
        cur))))

(defun claude-code-ide-mcp--trace-attribute-edges (item root query-id box nodes
                                                        imports)
  "Collect the edges attribute ITEM declares, under ROOT, into BOX.
QUERY-ID names the query that reached ITEM, NODES gathers the declarations the
edges start at, and IMPORTS are the names the file brings into scope."
  (when-let* ((names (claude-code-ide-mcp--trace-names-in item))
              (kind (cdr (assoc (treesit-node-text (car names) t)
                                (plist-get (claude-code-ide-mcp--trace-rules)
                                           :attributes))))
              (owner (claude-code-ide-mcp--trace-attribute-owner item))
              (from-id (claude-code-ide-mcp--trace-declaration-id
                        owner root query-id imports nodes)))
    (dolist (to (cdr names))
      (push (list :kind kind
                  :from (list :id from-id)
                  :to (claude-code-ide-mcp--trace-ref to))
            (car box)))
    t))

(defun claude-code-ide-mcp--trace-signature-end (decl)
  "Return where DECL's signature stops: the start of whatever body it has."
  (let ((body (treesit-node-child-by-field-name decl "body")))
    (if body (treesit-node-start body) (treesit-node-end decl))))

(defun claude-code-ide-mcp--trace-param-edges (decl from-id box)
  "Collect the types named in DECL's signature, sourced at FROM-ID, into BOX."
  (let ((seen (make-hash-table :test 'equal)))
    (dolist (node (claude-code-ide-mcp--trace-feature-nodes
                   'type (treesit-node-start decl)
                   (claude-code-ide-mcp--trace-signature-end decl)))
      (let ((name (treesit-node-text node t)))
        (when (and (claude-code-ide-mcp--trace-name-node-p node)
                   (not (gethash name seen)))
          (puthash name t seen)
          (push (list :kind "param"
                      :from (list :id from-id)
                      :to (claude-code-ide-mcp--trace-ref node))
                (car box)))))))

(defun claude-code-ide-mcp--trace-calls-around (node)
  "Return the calls NODE takes part in, both inside it and above it.
A call written on one line sits below the block the seed matched, while a
call spread over several lines has that block among its arguments, so
neither direction alone finds them all.  Calls are told apart by both their
ends: every call in `app.a().b().c()' begins at `app', so a start position
alone would collapse a chain to its first link."
  (let ((seen (make-hash-table :test 'equal))
        (out '()))
    (cl-flet ((remember (call)
                (let ((key (cons (treesit-node-start call) (treesit-node-end call))))
                  (unless (gethash key seen)
                    (puthash key t seen)
                    (push call out)))))
      (dolist (name (claude-code-ide-mcp--trace-feature-nodes
                     'function (treesit-node-start node) (treesit-node-end node)))
        (when-let* ((call (claude-code-ide-mcp--trace-call-of name)))
          (remember call)))
      (let ((cur (treesit-node-parent node)))
        (while cur
          (when (treesit-node-child-by-field-name cur "arguments")
            (remember cur))
          (setq cur (treesit-node-parent cur)))))
    (nreverse out)))

(defun claude-code-ide-mcp--trace-declaration-id (decl root query-id imports nodes)
  "Return DECL's node id under ROOT, recording DECL as a node in NODES.
An edge starting at a declaration is the answer to \"who registers this\", and
an answer nobody can open is half an answer, so the declaration is stored with
its own line rather than left as a name the store knows nothing else about."
  (let* ((text (claude-code-ide-mcp--trace-normalized-text decl))
         (record (claude-code-ide-mcp--trace-node-record
                  (buffer-file-name) root decl query-id text imports)))
    (unless (string-empty-p text)
      (push record (car nodes)))
    (plist-get record :id)))

(defun claude-code-ide-mcp--trace-edges-at (node record attributes root query-id
                                                 box nodes imports)
  "Collect the edges NODE takes part in, given its RECORD, into BOX.
Only the shapes the seed actually landed on are read -- a registering call it
takes part in, an attribute on its declaration, a signature it is -- so the
graph stays what the trace touched.  ATTRIBUTES holds the file's attributes
by owner, ROOT is the project root and QUERY-ID names the query."
  (dolist (call (claude-code-ide-mcp--trace-calls-around node))
    (claude-code-ide-mcp--trace-register-edges
     call
     (claude-code-ide-mcp--trace-declaration-id
      (or (claude-code-ide-mcp--trace-declaration call) call)
      root query-id imports nodes)
     box))
  (when-let* ((decl (claude-code-ide-mcp--trace-declaration node)))
    (dolist (item (gethash (treesit-node-start decl) attributes))
      (claude-code-ide-mcp--trace-attribute-edges
       item root query-id box nodes imports)))
  (when (and (claude-code-ide-mcp--trace-declaration-p node)
             (plist-get record :id))
    (claude-code-ide-mcp--trace-param-edges node (plist-get record :id) box)))

(defun claude-code-ide-mcp--trace-attribute-table ()
  "Return the current buffer's attributes, keyed by the declaration each owns."
  (let ((table (make-hash-table :test 'eql)))
    (dolist (node (claude-code-ide-mcp--trace-feature-nodes
                   'attribute (point-min) (point-max)))
      (when-let* ((owner (claude-code-ide-mcp--trace-attribute-owner node)))
        (push node (gethash (treesit-node-start owner) table))))
    table))

(defun claude-code-ide-mcp--trace-collect (matches root query-id)
  "Turn MATCHES, a list of (FILE . LINE), into node records under ROOT.
Returns a plist of :records, :unparsed -- matches no tree-sitter block
encloses -- and :empty, blocks whose text is nothing but comments.  QUERY-ID
names the query that produced MATCHES."
  (let ((by-file (make-hash-table :test 'equal))
        (records '())
        (seen-files '())
        (unparsed 0)
        (empty 0)
        (box (list nil))
        (node-box (list nil)))
    (dolist (m matches)
      (push (cdr m) (gethash (car m) by-file)))
    (maphash
     (lambda (file lines)
       (let ((inhibit-redisplay t))
         (claude-code-ide-mcp--with-temp-visit file
           (save-excursion
             (let* ((seen (make-hash-table :test 'equal))
                    (attributes (claude-code-ide-mcp--trace-attribute-table))
                    (imports (claude-code-ide-mcp--trace-import-names)))
               (push (list :k "file"
                           :path (file-relative-name file root)
                           :hash (claude-code-ide-mcp--trace-file-hash file)
                           :imports (vconcat imports)
                           :at (format-time-string "%FT%T%z"))
                     seen-files)
               (dolist (line (sort (copy-sequence lines) #'<))
                 (if-let* ((node (claude-code-ide-mcp--trace-block-node line)))
                     (let ((key (cons (treesit-node-start node)
                                      (treesit-node-end node))))
                       (unless (gethash key seen)
                         (puthash key t seen)
                         (let ((text (claude-code-ide-mcp--trace-normalized-text
                                      node)))
                           (if (string-empty-p text)
                               (setq empty (1+ empty))
                             (let ((record (claude-code-ide-mcp--trace-node-record
                                            file root node query-id text
                                            imports)))
                               (push record records)
                               (ignore-errors
                                 (claude-code-ide-mcp--trace-edges-at
                                  node record attributes root query-id box
                                  node-box imports)))))))
                   (setq unparsed (1+ unparsed)))))))))
     by-file)
    (list :records (nreverse records)
          ;; The declarations edges start at are stored too, but kept out of
          ;; :records: those answer the clone question and are what the block
          ;; cap counts, and a registering plugin is neither.
          :endpoints (nreverse (car node-box))
          :edges (nreverse (car box))
          :files (nreverse seen-files)
          :unparsed unparsed
          :empty empty)))

(defconst claude-code-ide-mcp--trace-replay-cap 20
  "How many stored queries a changed file is re-asked, newest first.
Replaying is what rebuilds a file's nodes after it moves under the store, and
a repository accumulates queries without bound, so the oldest are dropped
rather than letting one edit re-ask everything ever asked.")

(defun claude-code-ide-mcp--trace-git (root &rest args)
  "Run git in ROOT with ARGS, returning its output, or nil when it fails."
  (let ((default-directory (file-name-as-directory root)))
    (with-temp-buffer
      (when (zerop (apply #'call-process "git" nil t nil "--no-pager" args))
        (buffer-string)))))

(defun claude-code-ide-mcp--trace-git-head (root)
  "Return the commit ROOT is on, or nil when ROOT is not a repository."
  (when-let* ((out (claude-code-ide-mcp--trace-git root "rev-parse" "HEAD")))
    (string-trim out)))

(defun claude-code-ide-mcp--trace-git-dirty (root)
  "Return the paths in ROOT that are not committed as they stand."
  (when-let* ((out (claude-code-ide-mcp--trace-git root "status" "--porcelain")))
    (delq nil
          (mapcar (lambda (line)
                    (when (> (length line) 3)
                      (string-trim (substring line 3))))
                  (split-string out "\n" t)))))

(defun claude-code-ide-mcp--trace-git-changes (root sha)
  "Return (STATUS . PATH) cells for how ROOT's tree now differs from SHA.
The comparison runs against the working tree rather than another commit, so
an edit nobody has committed counts as a change.  A rename is reported as the
old path going away and the new one arriving, which is what the store has to
do with it until node ids learn to move."
  (when-let* ((out (claude-code-ide-mcp--trace-git
                    root "diff" "--name-status" "-M" sha)))
    (let ((cells '()))
      (dolist (line (split-string out "\n" t))
        (let* ((parts (split-string line "\t" t))
               (status (and (cdr parts) (substring (car parts) 0 1))))
          (cond
           ((null status) nil)
           ((equal status "R")
            (push (cons "D" (nth 1 parts)) cells)
            (push (cons "M" (nth 2 parts)) cells))
           (t (push (cons status (car (last parts))) cells)))))
      (nreverse cells))))

(defun claude-code-ide-mcp--trace-gone-record (id reason)
  "Return a record saying ID is no longer there, for REASON."
  (list :k "gone" :id id :reason reason
        :at (format-time-string "%FT%T%z")))

(defun claude-code-ide-mcp--trace-nodes-of-file (known file)
  "Return the ids KNOWN holds for FILE."
  (let ((out '()))
    (maphash (lambda (id its-file)
               (when (equal its-file file) (push id out)))
             (plist-get known :node-files))
    out))

(defun claude-code-ide-mcp--trace-replay-file (file root known)
  "Re-ask KNOWN's stored queries of FILE alone, under ROOT.
Returns a plist of :records :edges and :queries, the ids of the queries that
were re-asked.  A node is only ever rebuilt by the query that first found it,
so its provenance survives the rebuild."
  (let ((records '())
        (edges '())
        (files '())
        (asked '()))
    (dolist (query (seq-take (reverse (plist-get known :queries))
                             claude-code-ide-mcp--trace-replay-cap))
      (let* ((matches (claude-code-ide-mcp--grep-block-search
                       (plist-get query :pattern) file))
             (collected (and matches
                             (claude-code-ide-mcp--trace-collect
                              matches root (plist-get query :id)))))
        (push (plist-get query :id) asked)
        (when collected
          (setq records (append records
                                (plist-get collected :records)
                                (plist-get collected :endpoints)))
          (setq edges (append edges (plist-get collected :edges)))
          (setq files (append files (plist-get collected :files))))))
    (list :records records :edges edges :files files :queries (nreverse asked))))

(defun claude-code-ide-mcp--trace-refresh (root known)
  "Bring KNOWN's view of ROOT up to date with what the tree now holds.
Returns a plist of :records :edges :gone :deleted :changed :replayed and
:how, the last saying which way staleness was detected -- or why it was not."
  (let* ((scan (plist-get known :scan))
         (sha (plist-get scan :sha))
         (changes (and sha (claude-code-ide-mcp--trace-git-changes root sha)))
         (previously-dirty (append (plist-get scan :dirty) nil))
         (records '())
         (edges '())
         (gone '())
         (deleted 0)
         (changed 0)
         (touched '())
         (files '())
         (replayed 0))
    (cond
     ((null (claude-code-ide-mcp--trace-git-head root))
      (list :how "not a repository, staleness unchecked"
            :records nil :edges nil :gone nil :deleted 0 :changed 0 :replayed 0))
     ((null sha)
      (list :how "first scan, nothing to compare against"
            :records nil :edges nil :gone nil :deleted 0 :changed 0 :replayed 0))
     (t
      (dolist (cell changes)
        (if (equal (car cell) "D")
            ;; git keeps reporting a deletion until it is committed, so the
            ;; count follows the nodes actually retired, not the report.
            (when-let* ((ids (claude-code-ide-mcp--trace-nodes-of-file
                              known (cdr cell))))
              (setq deleted (1+ deleted))
              (dolist (id ids)
                (push (claude-code-ide-mcp--trace-gone-record id "file deleted")
                      gone)))
          (push (cdr cell) touched)))
      (dolist (path previously-dirty)
        (unless (member path touched) (push path touched)))
      (dolist (path (delete-dups touched))
        (let* ((full (expand-file-name path root))
               (hash (claude-code-ide-mcp--trace-file-hash full)))
          ;; git keeps calling a file changed for as long as its edit is
          ;; uncommitted, so without this the same file is replayed on every
          ;; trace forever.  The byte hash says whether it moved since the
          ;; store last read it, which is the question that matters.
          (when (and hash (not (equal hash (gethash path (plist-get known :files)))))
            (setq changed (1+ changed))
            (let* ((replay (claude-code-ide-mcp--trace-replay-file full root known))
                   (rebuilt (mapcar (lambda (r) (plist-get r :id))
                                    (plist-get replay :records))))
              (setq replayed (+ replayed (length (plist-get replay :queries))))
              (setq records (append records (plist-get replay :records)))
              (setq edges (append edges (plist-get replay :edges)))
              (setq files (append files (plist-get replay :files)))
              (dolist (id (claude-code-ide-mcp--trace-nodes-of-file known path))
                (when (and (member (gethash id (plist-get known :node-queries))
                                   (plist-get replay :queries))
                           (not (member id rebuilt)))
                  (push (claude-code-ide-mcp--trace-gone-record id "no longer there")
                        gone)))))))
      (list :how (format "git diff against %s" (substring sha 0 8))
            :records records
            :edges edges
            :gone (nreverse gone)
            :files (nreverse files)
            :deleted deleted
            :changed changed
            :replayed replayed)))))

(defun claude-code-ide-mcp--trace-scan-record (root)
  "Return the record of what ROOT looked like when this trace read it."
  (let ((sha (claude-code-ide-mcp--trace-git-head root)))
    (list :k "scan"
          :sha (or sha "")
          :dirty (vconcat (claude-code-ide-mcp--trace-git-dirty root))
          :at (format-time-string "%FT%T%z"))))

(defun claude-code-ide-mcp--trace-uri-to-path (uri)
  "Return the file URI names."
  (funcall (if (fboundp 'eglot-uri-to-path) 'eglot-uri-to-path 'eglot--uri-to-path)
           uri))

(defun claude-code-ide-mcp--trace-definition-at (file line col)
  "Return (TARGET-FILE . TARGET-LINE) for what is defined at FILE LINE COL.
The server is asked at the reference itself rather than by name, because a
name query cannot tell a definition from a re-export of it, and an endpoint
that names the wrong file is the failure this graph exists to prevent."
  (ignore-errors
    (claude-code-ide-mcp--at-position
     file line col
     (lambda ()
       (when-let* ((server (eglot-current-server))
                   (raw (condition-case nil
                            (eglot--request
                             server :textDocument/definition
                             (claude-code-ide-mcp--textdoc-position-params)
                             :timeout 10)
                          (error nil)))
                   (hit (cond ((vectorp raw) (and (> (length raw) 0) (aref raw 0)))
                              ((null raw) nil)
                              (t raw)))
                   (uri (or (plist-get hit :targetUri) (plist-get hit :uri)))
                   (range (or (plist-get hit :targetSelectionRange)
                              (plist-get hit :targetRange)
                              (plist-get hit :range))))
         (cons (claude-code-ide-mcp--trace-uri-to-path uri)
               (1+ (plist-get (plist-get range :start) :line))))))))

(defun claude-code-ide-mcp--trace-declaration-record-at (file line root query-id)
  "Return the record of the declaration at FILE LINE, relative to ROOT.
QUERY-ID names the query that reached it."
  (when (and file (file-readable-p file))
    (let ((inhibit-redisplay t))
      (claude-code-ide-mcp--with-temp-visit file
        (save-excursion
          (goto-char (point-min))
          (forward-line (1- line))
          (back-to-indentation)
          (when-let* ((node (and (treesit-parser-list) (treesit-node-at (point))))
                      (decl (claude-code-ide-mcp--trace-declaration node))
                      (text (claude-code-ide-mcp--trace-normalized-text decl)))
            (unless (string-empty-p text)
              (claude-code-ide-mcp--trace-node-record
               file root decl query-id text))))))))

(defun claude-code-ide-mcp--trace-resolve-one (endpoint ctx)
  "Resolve ENDPOINT to (ID . KIND) through the server, honouring CTX's caps."
  (let ((files (plist-get ctx :files))
        (file (plist-get endpoint :file))
        (unresolved (cons (plist-get endpoint :name) "name")))
    (if (and (not (gethash file files))
             (>= (hash-table-count files) claude-code-ide-mcp--trace-lsp-file-cap))
        (progn (cl-incf (car (plist-get ctx :capped)))
               unresolved)
      (puthash file t files)
      (if-let* ((location (claude-code-ide-mcp--trace-definition-at
                           file (plist-get endpoint :line) (plist-get endpoint :col))))
          (if (not (string-prefix-p (plist-get ctx :root)
                                    (expand-file-name (car location))))
              ;; A definition outside the project is real but not this
              ;; graph's to hold: a node id reaching into a package cache
              ;; would key on a path that changes with every upgrade.
              (cons (plist-get endpoint :name) "external")
            (if-let* ((record (claude-code-ide-mcp--trace-declaration-record-at
                               (car location) (cdr location)
                               (plist-get ctx :root) (plist-get ctx :query))))
                (progn (puthash (plist-get record :id) record (plist-get ctx :nodes))
                       (cons (plist-get record :id) "node"))
              unresolved))
        unresolved))))

(defun claude-code-ide-mcp--trace-endpoint (endpoint ctx)
  "Return (ID . KIND) for ENDPOINT, reusing what CTX already resolved."
  (if-let* ((id (plist-get endpoint :id)))
      (cons id "node")
    (let ((cache (plist-get ctx :cache))
          (key (format "%s|%s|%s"
                       (plist-get endpoint :file)
                       (plist-get endpoint :line)
                       (plist-get endpoint :col))))
      (or (gethash key cache)
          (puthash key (claude-code-ide-mcp--trace-resolve-one endpoint ctx) cache)))))

(defun claude-code-ide-mcp--trace-edge-record (edge from to query-id)
  "Return the store record for EDGE running FROM to TO, found by QUERY-ID.
An endpoint whose kind is \"name\" is one the server would not resolve, and
saying so is the point: an unresolved endpoint must not read as a resolved
one."
  (list :k "edge"
        :kind (plist-get edge :kind)
        :from (car from)
        :from_kind (cdr from)
        :to (car to)
        :to_kind (cdr to)
        :ev "treesit"
        :q query-id))

(defun claude-code-ide-mcp--trace-resolve (edges root query-id)
  "Resolve the endpoints of EDGES under ROOT, as found by QUERY-ID.
Returns a plist of the edge records, the target nodes resolving them turned
up, and what the resolution cost."
  (let ((ctx (list :cache (make-hash-table :test 'equal)
                   :nodes (make-hash-table :test 'equal)
                   :files (make-hash-table :test 'equal)
                   :capped (list 0)
                   :root root
                   :query query-id))
        (out '()))
    (dolist (edge edges)
      (push (claude-code-ide-mcp--trace-edge-record
             edge
             (claude-code-ide-mcp--trace-endpoint (plist-get edge :from) ctx)
             (claude-code-ide-mcp--trace-endpoint (plist-get edge :to) ctx)
             query-id)
            out))
    (let ((records (nreverse out)))
      (list :edges records
            :nodes (hash-table-values (plist-get ctx :nodes))
            :files (hash-table-count (plist-get ctx :files))
            :capped (car (plist-get ctx :capped))
            :unresolved (seq-count
                         (lambda (e) (equal (plist-get e :to_kind) "name"))
                         records)))))

(defun claude-code-ide-mcp--trace-dedupe-files (records known)
  "Return the file RECORDS worth writing: one per path, and only when moved.
A file whose bytes match what KNOWN already holds is written again by nobody,
which is what keeps an idle trace from appending a line per file it read."
  (let ((seen (make-hash-table :test 'equal))
        (out '()))
    (dolist (rec records)
      (let ((path (plist-get rec :path)))
        (unless (or (gethash path seen)
                    (equal (plist-get rec :hash)
                           (gethash path (plist-get known :files))))
          (puthash path t seen)
          (push rec out))))
    (nreverse out)))

(defun claude-code-ide-mcp--trace-dedupe-nodes (records)
  "Return RECORDS with repeats of the same id dropped, first one winning.
A single trace derives one node several times over -- once per stored query
replayed against its file, once more if the seed reaches it -- and writing
each of them would grow the store by a multiple of what actually changed.
The first is kept because the replayed records come first, and they carry the
query that originally found the node rather than the one running now."
  (let ((seen (make-hash-table :test 'equal))
        (out '()))
    (dolist (rec records)
      (let ((id (plist-get rec :id)))
        (unless (gethash id seen)
          (puthash id t seen)
          (push rec out))))
    (nreverse out)))

(defun claude-code-ide-mcp--trace-dedupe-edges (edges)
  "Return EDGES with repeats of the same identity dropped.
One seed reaches the same registration from several of its own matches, so
the same edge is derived more than once within a single trace."
  (let ((seen (make-hash-table :test 'equal))
        (out '()))
    (dolist (edge edges)
      (let ((key (claude-code-ide-mcp--trace-edge-key edge)))
        (unless (gethash key seen)
          (puthash key t seen)
          (push edge out))))
    (nreverse out)))

(defun claude-code-ide-mcp--trace-edge-key (record)
  "Return the identity of edge RECORD, which is its kind and its ends."
  (format "%s|%s|%s"
          (plist-get record :kind)
          (plist-get record :from)
          (plist-get record :to)))

(defun claude-code-ide-mcp--trace-classify (records known changed-imports)
  "Split RECORDS against what KNOWN holds, given CHANGED-IMPORTS by file.
Returns a plist of :new :changed :context :moved and :unchanged record lists.

A `context' node is the one this whole mechanism exists for: its own text is
untouched, so its hash agrees, but an import it names now resolves somewhere
else, and reporting it as unchanged would be a lie about meaning.  A `moved'
node only shifted lines, and is written back quietly so the locator keeps up."
  (let ((hashes (plist-get known :nodes))
        (lines (plist-get known :node-lines))
        (uses (plist-get known :node-uses))
        (new '()) (changed '()) (context '()) (moved '()) (unchanged '()))
    (dolist (rec records)
      (let* ((id (plist-get rec :id))
             (seen (gethash id hashes))
             (mine (append (plist-get rec :uses) nil))
             ;; Absent and empty are different answers: a record written
             ;; before this field existed knows nothing about its imports,
             ;; and saying its meaning shifted would be the false claim this
             ;; whole field exists to prevent.  It is written back quietly.
             (raw (gethash id uses))
             (theirs (append raw nil))
             (moved-names (gethash (plist-get rec :file) changed-imports)))
        (cond ((null seen) (push rec new))
              ((not (equal seen (plist-get rec :hash))) (push rec changed))
              ((seq-intersection mine moved-names) (push rec context))
              ((and raw (not (equal mine theirs))) (push rec context))
              ((or (null raw)
                   (not (equal (gethash id lines) (plist-get rec :line))))
               (push rec moved))
              (t (push rec unchanged)))))
    (list :new (nreverse new)
          :changed (nreverse changed)
          :context (nreverse context)
          :moved (nreverse moved)
          :unchanged (nreverse unchanged))))

(defun claude-code-ide-mcp--trace-clone-groups (records)
  "Group RECORDS by content hash, largest group first, singletons dropped."
  (let ((by-hash (make-hash-table :test 'equal))
        (groups '()))
    (dolist (rec records)
      (push rec (gethash (plist-get rec :hash) by-hash)))
    (maphash (lambda (hash recs)
               (when (cdr recs)
                 (push (cons hash (nreverse recs)) groups)))
             by-hash)
    (sort groups (lambda (a b) (> (length (cdr a)) (length (cdr b)))))))

(defun claude-code-ide-mcp--trace-render-answer (records)
  "Render the clone answer for RECORDS."
  (let* ((groups (claude-code-ide-mcp--trace-clone-groups records))
         (grouped (apply #'+ (mapcar (lambda (g) (length (cdr g))) groups))))
    (cond
     ((null records)
      "answer: absent -- the seed matched nothing, recorded as such\n")
     ((null groups)
      (format "answer: 0 clone-groups over %d blocks (all unique)\n"
              (length records)))
     (t
      (format "answer: %d clone-groups over %d blocks\n%s%s"
              (length groups) (length records)
              (mapconcat
               (lambda (group)
                 (format "  #%s  %dx  %s  %s\n"
                         (car group) (length (cdr group))
                         (string-join
                          (delete-dups (mapcar (lambda (r) (plist-get r :kind))
                                               (cdr group)))
                          "/")
                         (mapconcat (lambda (r) (plist-get r :id)) (cdr group) "  ")))
               groups "")
              (format "  %d blocks unique\n" (- (length records) grouped)))))))

(defun claude-code-ide-mcp--trace-render-edges (resolved fresh)
  "Render the edge summary for RESOLVED, of which FRESH are not yet stored."
  (let ((edges (claude-code-ide-mcp--trace-dedupe-edges
                (plist-get resolved :edges)))
        (kinds (make-hash-table :test 'equal)))
    (dolist (edge edges)
      (puthash (plist-get edge :kind) (1+ (gethash (plist-get edge :kind) kinds 0))
               kinds))
    (if (null edges)
        "edges: none in what the seed reached\n"
      (format "edges: %d (%s), %d new, %d endpoints left as names\n"
              (length edges)
              (string-join
               (sort (let ((out '()))
                       (maphash (lambda (k n) (push (format "%s %d" k n) out)) kinds)
                       out)
                     #'string<)
               ", ")
              (length fresh)
              (plist-get resolved :unresolved)))))

(defun claude-code-ide-mcp--trace-render-refresh (refreshed)
  "Render what REFRESHED brought up to date before the seed ran."
  (format "refreshed: %s -- %d files changed, %d deleted, %d nodes re-derived, %d gone, %d queries replayed\n"
          (plist-get refreshed :how)
          (plist-get refreshed :changed)
          (plist-get refreshed :deleted)
          (length (plist-get refreshed :records))
          (length (plist-get refreshed :gone))
          (plist-get refreshed :replayed)))

(defun claude-code-ide-mcp--trace-render (records counts query store omitted
                                                  collected resolved fresh-edges
                                                  refreshed)
  "Render the whole trace report.
RECORDS are the node records, COUNTS the plist from
`claude-code-ide-mcp--trace-classify', QUERY the query record, STORE the
store path, OMITTED the file count dropped by the cap, COLLECTED the plist
from `claude-code-ide-mcp--trace-collect', RESOLVED the plist from
`claude-code-ide-mcp--trace-resolve' and FRESH-EDGES those it added."
  (concat
   (claude-code-ide-mcp--trace-render-answer records)
   (claude-code-ide-mcp--trace-render-edges resolved fresh-edges)
   (claude-code-ide-mcp--trace-render-refresh refreshed)
   (format "query: %s  rg '%s'  path=%s  -> %d blocks in %d files\n"
           (plist-get query :id) (plist-get query :pattern)
           (plist-get query :path) (length records)
           (length (delete-dups (mapcar (lambda (r) (plist-get r :file)) records))))
   (format "appended: nodes %d new, %d changed, %d context-changed, %d moved, %d unchanged (not re-appended)\n"
           (length (plist-get counts :new))
           (length (plist-get counts :changed))
           (length (plist-get counts :context))
           (length (plist-get counts :moved))
           (length (plist-get counts :unchanged)))
   (if (plist-get counts :context)
       (format "context-changed: %s\n"
               (string-join (mapcar (lambda (r) (plist-get r :id))
                                    (seq-take (plist-get counts :context) 10))
                            "  "))
     "")
   (format "store: %s\n" store)
   (format "frontier: %d files omitted by cap, %d matches with no tree-sitter block, %d comment-only blocks, %d endpoints past the server cap\n"
           omitted
           (plist-get collected :unparsed)
           (plist-get collected :empty)
           (plist-get resolved :capped))))

(defun claude-code-ide-mcp-trace (pattern &optional path cap ask files)
  "Trace PATTERN through the project and record what it finds as graph nodes.
Every hit grows to its enclosing tree-sitter block, which becomes a node
identified by file, declaration path and, for a block below a declaration,
its position within it -- never a line number.  Each node is stamped with a
hash of its text after comments and whitespace are removed, so blocks sharing
a hash are clones however they are named.  New and changed nodes are
appended to the project's JSONL store, and the report states how many, so the
caller never has to take the write on trust.  PATH narrows the search root,
CAP bounds the blocks examined (default 200, 0 = unlimited), FILES bounds the
files visited (default 100, 0 = unlimited) and ASK records the question this
query answers."
  (condition-case err
      (let* ((cap (if (numberp cap) cap claude-code-ide-mcp--trace-block-cap))
             (files (if (numberp files) files claude-code-ide-mcp--trace-file-cap))
             (root (claude-code-ide-mcp--trace-project-root
                    (claude-code-ide-mcp--grep-block-root path)))
             (store (claude-code-ide-mcp--trace-store-file root))
             (query-id (format-time-string "q%Y%m%dT%H%M%S%3N"))
             (limited (claude-code-ide-mcp--limit-matches-by-file
                       (claude-code-ide-mcp--grep-block-search pattern path)
                       files))
             (known (claude-code-ide-mcp--trace-known store))
             (refreshed (claude-code-ide-mcp--trace-refresh root known))
             (collected (claude-code-ide-mcp--trace-collect
                         (car limited) root query-id))
             (records (if (> cap 0)
                          (seq-take (plist-get collected :records) cap)
                        (plist-get collected :records)))
             (resolved (claude-code-ide-mcp--trace-resolve
                        (append (plist-get refreshed :edges)
                                (plist-get collected :edges))
                        root query-id))
             (file-records (claude-code-ide-mcp--trace-dedupe-files
                            (append (plist-get refreshed :files)
                                    (plist-get collected :files))
                            known))
             (counts (claude-code-ide-mcp--trace-classify
                      (claude-code-ide-mcp--trace-dedupe-nodes
                       (append (plist-get refreshed :records)
                               records
                               (plist-get collected :endpoints)
                               (plist-get resolved :nodes)))
                      known
                      (claude-code-ide-mcp--trace-changed-imports
                       file-records known)))
             (fresh-edges (seq-remove
                           (lambda (edge)
                             (gethash (claude-code-ide-mcp--trace-edge-key edge)
                                      (plist-get known :edges)))
                           (plist-get resolved :edges)))
             (query (list :k "query" :id query-id :tool "rg"
                          :pattern pattern
                          :path (or path "")
                          :ask (or ask "")
                          :n (length records)
                          :at (format-time-string "%FT%T%z"))))
        (claude-code-ide-mcp--trace-append
         store
         (append (list query)
                 file-records
                 (plist-get refreshed :gone)
                 (plist-get counts :new)
                 (plist-get counts :changed)
                 (plist-get counts :context)
                 (plist-get counts :moved)
                 (claude-code-ide-mcp--trace-dedupe-edges fresh-edges)
                 (unless (or records (plist-get resolved :edges))
                   (list (list :k "absent" :q query-id :claim pattern)))
                 (list (claude-code-ide-mcp--trace-scan-record root))))
        (claude-code-ide-mcp--trace-render
         records counts query store (cdr limited) collected
         resolved fresh-edges refreshed))
    (error (format "Error tracing: %s" (error-message-string err)))))

(claude-code-ide-make-tool
 :function #'claude-code-ide-mcp-trace
 :name "trace"
 :description "Search a seed pattern, grow every hit to its enclosing tree-sitter block, and record each block as a graph node in a per-project JSONL store. A node is identified by file, declaration path and, when it sits below a declaration, its position inside it -- never a line number -- and carries a hash of its text with comments and whitespace removed, so blocks sharing a hash are clones however they are named. Each clone group names the node kind, since a duplicated idiom is usually an inner block rather than a whole function. Comment-only blocks are refused. Every registration, ordering, attribute and signature the seed reaches becomes an edge, whose endpoints the language server resolves at the reference itself, and an endpoint it will not resolve stays a bare name rather than passing as a resolved one. Answers the clone query directly and reports how many nodes and edges were appended, so the caller can check the write instead of trusting it. Args: pattern (rg regex seed), path (search root, default project root), cap (max blocks, default 200, 0=unlimited), ask (the question this query answers, stored with it), files (max files visited, default 100, 0=unlimited). The report ends with what the run did not reach; read it before calling an answer complete."
 :args '((:name "pattern"
          :type string
          :description "rg regex to seed the trace")
         (:name "path"
          :type string
          :description "Search root dir or file; default project root"
          :optional t)
         (:name "cap"
          :type number
          :description "Max blocks turned into nodes; default 200, 0=unlimited"
          :optional t)
         (:name "ask"
          :type string
          :description "The question this query answers; stored alongside it"
          :optional t)
         (:name "files"
          :type number
          :description "Max distinct files visited; default 100, 0=unlimited. Raise it when the question needs every site, since a capped answer is not the whole answer"
          :optional t)))

;;; graph: read what trace wrote, without touching code or a language server.

(defconst claude-code-ide-mcp--graph-line-cap 120
  "Most edge lines one graph answer prints before it says what it dropped.")

(defun claude-code-ide-mcp--graph-name-of (id)
  "Return the last name in ID's declaration path."
  (let ((parts (split-string (car (split-string id "@")) "::" t)))
    (car (last parts))))

(defun claude-code-ide-mcp--graph-candidates (from known)
  "Return the node ids in KNOWN that FROM could mean.
An exact id wins alone; otherwise every node whose own name is FROM answers,
and a name matching several nodes is reported as such rather than guessed at."
  (let ((ids '()))
    (maphash (lambda (id _hash)
               (when (or (equal id from)
                         (equal (claude-code-ide-mcp--graph-name-of id) from))
                 (push id ids)))
             (plist-get known :nodes))
    (if (member from ids) (list from) (nreverse ids))))

(defun claude-code-ide-mcp--graph-endpoint-known-p (from known)
  "Non-nil when any edge in KNOWN runs to or from the bare name FROM."
  (seq-some (lambda (edge)
              (or (equal (plist-get edge :from) from)
                  (equal (plist-get edge :to) from)))
            (plist-get known :edge-list)))

(defun claude-code-ide-mcp--graph-touching (id kinds direction known)
  "Return the edges of KINDS in KNOWN that touch ID in DIRECTION.
Each comes back as (SIDE . EDGE), SIDE being `in' or `out'."
  (let ((out '()))
    (dolist (edge (plist-get known :edge-list))
      (when (or (null kinds) (member (plist-get edge :kind) kinds))
        (when (and (memq direction '(out both))
                   (equal (plist-get edge :from) id))
          (push (cons 'out edge) out))
        (when (and (memq direction '(in both))
                   (equal (plist-get edge :to) id))
          (push (cons 'in edge) out))))
    (nreverse out)))

(defun claude-code-ide-mcp--graph-locator (id known)
  "Return ID's file and line as one string, or an empty one when unknown."
  (let ((file (gethash id (plist-get known :node-files)))
        (line (gethash id (plist-get known :node-lines))))
    (if (and file line) (format "  %s:%d" file line) "")))

(defun claude-code-ide-mcp--graph-edge-line (side edge known level)
  "Render EDGE seen from SIDE at LEVEL, reading locators out of KNOWN."
  (let* ((other (if (eq side 'in) (plist-get edge :from) (plist-get edge :to)))
         (kind (if (eq side 'in)
                   (plist-get edge :from_kind)
                 (plist-get edge :to_kind)))
         (mark (cond ((equal kind "node") "")
                     ((equal kind "external") "  (external)")
                     (t "  (unresolved name)"))))
    (format "%s%s %-10s %s%s%s   [%s %s]"
            (make-string (* 2 level) ?\s)
            (if (eq side 'in) "<-" "->")
            (plist-get edge :kind)
            other
            (if (equal kind "node")
                (claude-code-ide-mcp--graph-locator other known)
              "")
            mark
            (plist-get edge :ev)
            (plist-get edge :q))))

(defun claude-code-ide-mcp--graph-walk (id kinds direction depth known seen used)
  "Render ID's edges to DEPTH, of KINDS, in DIRECTION, reading KNOWN.
SEEN holds the ids already rendered and USED collects the query ids the
answer rests on, so the caller can print the queries a reviewer would re-run."
  (let ((lines '()))
    (cl-labels
        ((walk (node level)
           (when (and (< level depth) (not (gethash node seen)))
             (puthash node t seen)
             (dolist (pair (claude-code-ide-mcp--graph-touching
                            node kinds direction known))
               (let* ((edge (cdr pair))
                      (other (if (eq (car pair) 'in)
                                 (plist-get edge :from)
                               (plist-get edge :to))))
                 (puthash (plist-get edge :q) t used)
                 (push (claude-code-ide-mcp--graph-edge-line
                        (car pair) edge known level)
                       lines)
                 (walk other (1+ level)))))))
      (walk id 0))
    (nreverse lines)))

(defun claude-code-ide-mcp--graph-query-lines (used known)
  "Render the queries in KNOWN whose ids USED holds."
  (let ((out '()))
    (dolist (query (plist-get known :queries))
      (when (gethash (plist-get query :id) used)
        (push (format "  %s  rg '%s'  path=%s  n=%s%s"
                      (plist-get query :id)
                      (plist-get query :pattern)
                      (let ((path (plist-get query :path)))
                        (if (string-empty-p path) "<project root>" path))
                      (plist-get query :n)
                      (let ((ask (plist-get query :ask)))
                        (if (string-empty-p ask) "" (format "  ask=\"%s\"" ask))))
              out)))
    (nreverse out)))

(defun claude-code-ide-mcp--graph-summary (store known)
  "Render what STORE holds overall, from KNOWN.
Answering `what has been traced already' is the cheapest way to stop the next
reader re-deriving what this one already paid for."
  (let ((kinds (make-hash-table :test 'equal))
        (scan (plist-get known :scan)))
    (dolist (edge (plist-get known :edge-list))
      (puthash (plist-get edge :kind)
               (1+ (gethash (plist-get edge :kind) kinds 0)) kinds))
    (concat
     (format "store: %s\n" store)
     (format "holds: %d nodes, %d edges, %d queries, %d absent, %d files\n"
             (hash-table-count (plist-get known :nodes))
             (length (plist-get known :edge-list))
             (length (plist-get known :queries))
             (length (plist-get known :absent))
             (hash-table-count (plist-get known :files)))
     (if scan
         (format "last scan: %s at %s\n"
                 (substring (plist-get scan :sha) 0 (min 8 (length (plist-get scan :sha))))
                 (plist-get scan :at))
       "last scan: never\n")
     (if (zerop (hash-table-count kinds))
         ""
       (format "edge kinds: %s\n"
               (string-join
                (sort (let ((out '()))
                        (maphash (lambda (k n) (push (format "%s %d" k n) out)) kinds)
                        out)
                      #'string<)
                ", ")))
     (if (plist-get known :queries)
         (concat "queries:\n"
                 (mapconcat
                  (lambda (query)
                    (format "  %s  rg '%s'  n=%s%s"
                            (plist-get query :id)
                            (plist-get query :pattern)
                            (plist-get query :n)
                            (let ((ask (plist-get query :ask)))
                              (if (string-empty-p ask) ""
                                (format "  ask=\"%s\"" ask)))))
                  (plist-get known :queries) "\n")
                 "\n")
       "queries: none\n"))))

(defun claude-code-ide-mcp-graph (&optional from kinds depth direction path)
  "Read the stored graph around FROM, without opening code or a server.
FROM is a node id or a bare name; leaving it out reports what the store holds.
KINDS is a comma-separated edge filter, DEPTH the hops to walk (default 1),
DIRECTION one of \"in\", \"out\" or \"both\", and PATH picks the project.

Every line carries the evidence kind and the query that produced it, and the
queries themselves are printed below, because a reviewer is meant to re-run
them rather than take this answer on faith.  Nothing found is reported three
different ways -- never traced, traced and empty, or ambiguous -- since those
are three different facts and reading them as one is how a gap in the search
comes to look like a fact about the code."
  (condition-case err
      (let* ((root (claude-code-ide-mcp--trace-project-root
                    (claude-code-ide-mcp--grep-block-root path)))
             (store (claude-code-ide-mcp--trace-store-file root))
             (known (claude-code-ide-mcp--trace-known store))
             (depth (if (numberp depth) depth 1))
             (direction (cond ((equal direction "in") 'in)
                              ((equal direction "out") 'out)
                              (t 'both)))
             (kinds (and kinds (not (string-empty-p kinds))
                         (split-string kinds "[, ]+" t))))
        (cond
         ((not (file-readable-p store))
          (format "absent: nothing has been traced into %s yet\n" store))
         ((or (null from) (string-empty-p from))
          (claude-code-ide-mcp--graph-summary store known))
         (t
          (let ((candidates (claude-code-ide-mcp--graph-candidates from known)))
            (cond
             ((> (length candidates) 1)
              (format "ambiguous: '%s' names %d nodes, none chosen\n%s"
                      from (length candidates)
                      (mapconcat (lambda (id) (format "  %s%s" id
                                                      (claude-code-ide-mcp--graph-locator
                                                       id known)))
                                 candidates "\n")))
             ((and (null candidates)
                   (not (claude-code-ide-mcp--graph-endpoint-known-p from known)))
              (format "absent: no node or endpoint named '%s' -- nothing has traced it\n%s"
                      from
                      (claude-code-ide-mcp--graph-summary store known)))
             (t
              (let* ((id (or (car candidates) from))
                     (used (make-hash-table :test 'equal))
                     (lines (claude-code-ide-mcp--graph-walk
                             id kinds direction depth known
                             (make-hash-table :test 'equal) used))
                     (shown (seq-take lines claude-code-ide-mcp--graph-line-cap)))
                (concat
                 (format "node: %s%s%s\n" id
                         (claude-code-ide-mcp--graph-locator id known)
                         (let ((hash (gethash id (plist-get known :nodes))))
                           (if hash (format "  #%s" hash) "  (endpoint only)")))
                 (if lines
                     (concat (string-join shown "\n") "\n")
                   (format "  no %s edge here -- traced, and there is none\n"
                           (if kinds (string-join kinds "/") "")))
                 (when (> (length lines) (length shown))
                   (format "  %d more edges not shown\n"
                           (- (length lines) (length shown))))
                 (let ((queries (claude-code-ide-mcp--graph-query-lines used known)))
                   (if queries
                       (concat "queries:\n" (string-join queries "\n") "\n")
                     ""))
                 (format "counted: %d edges at depth %d, %s\n"
                         (length lines) depth
                         (cond ((eq direction 'in) "incoming only")
                               ((eq direction 'out) "outgoing only")
                               (t "both directions")))))))))))
    (error (format "Error reading graph: %s" (error-message-string err)))))

(claude-code-ide-make-tool
 :function #'claude-code-ide-mcp-graph
 :name "graph"
 :description "Read the graph `trace' recorded, with no language-server round trip and without opening any code. Give it a node id or a bare name to see what registers, orders, requires or takes that thing, and what it takes in turn; leave the name out to see what the store already holds, which is the cheap way to find out whether a question has been answered before. Every edge line carries its evidence kind and the id of the query that produced it, and those queries are printed underneath so a reviewer can re-run them instead of trusting the answer. Emptiness is reported three ways -- never traced, traced with no such edge, or a name matching several nodes -- because those are different facts. Args: from (node id or name; omit for a summary), kinds (comma-separated edge kinds), depth (hops, default 1), direction (in | out | both), path (project, default the current one)."
 :args '((:name "from"
          :type string
          :description "Node id or bare name; omit to summarise the store"
          :optional t)
         (:name "kinds"
          :type string
          :description "Comma-separated edge kinds to keep, e.g. registers,before"
          :optional t)
         (:name "depth"
          :type number
          :description "Hops to walk; default 1"
          :optional t)
         (:name "direction"
          :type string
          :description "in | out | both (default)"
          :optional t)
         (:name "path"
          :type string
          :description "Any path in the project whose store to read"
          :optional t)))

(provide 'claude-code-ide-extra-trace)
;;; claude-code-ide-extra-trace.el ends here
