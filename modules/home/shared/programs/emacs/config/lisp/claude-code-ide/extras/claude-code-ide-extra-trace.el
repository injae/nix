;;; claude-code-ide-extra-trace.el --- MCP tools: exploration graph -*- lexical-binding: t; -*-
;;; Commentary:

;; trace: seed a search, turn each hit into a graph node carrying a normalized
;; content hash, append the new nodes to a per-project JSONL store, and answer
;; the clone query in the same call.  The store admits only nodes, edges,
;; evidence kinds, queries and hashes -- never free prose, so every claim in it
;; stays re-runnable.
;;
;; The graph has two layers.  `contains', `arg' and `ref' are what the
;; language says: a declaration holds a parameter, a call fills one, a use
;; names something.  `registers', `in_set', `after', `run_if', `requires' and
;; `param' are readings of those, and they are written beside the relations
;; they were read from rather than instead of them.
;;
;; What a declaration, a call or a type is comes from the mode's own font-lock
;; features, and what kind of declaration it is comes from the node holding
;; it.  No grammar's node types are named here.  The per-language table holds
;; two things a grammar cannot say: which methods register, and what an
;; attribute name means.  Without it the language layer still comes out.
;;
;; Relations are read from the statement a match sits in, so a block normally
;; holds names the seed never reached.  Those are written on the node as
;; `unread' -- named, not followed, offered as the next seed.  The field is
;; absent, empty or filled, and those are three facts: unmeasured, nothing
;; left, this is what is left.

;;; Constraints:

;; One seed still derives relations in the thousands.  Scope with `path'.
;;
;; Nothing bounds how many files a seed reads, and a buffer per file stays
;; open for the whole call, so a wide seed can exhaust file descriptors.
;;
;; The frontier is half built: `unread' names the next hop, but as names
;; rather than node ids, so a caller seeds one of them by hand.
;;
;; Anything that bounds a result by taking a prefix needs an order of its
;; own.  ripgrep's walkers are parallel and its output order is not stable.
;;
;; `treesit-query-capture' without a region returns fewer captures than the
;; same query given one spanning the file, and says nothing about the
;; difference.  Pass point-min and point-max.
;;
;; `json-serialize' returns unibyte.  Write it from a unibyte buffer, or a
;; non-ASCII field stops the call to ask which coding system its raw bytes
;; want.
;;
;; A display column is not an LSP `:character'.  Wire positions come from
;; `eglot--pos-to-lsp-position'; nothing here may use `current-column'.
;;
;; A buffer opened here must carry `default-directory', or `project-current'
;; -- and so eglot -- resolves the file to whatever project the caller stood
;; in.
;;
;; How many endpoints resolve is not a property of the code.  The server
;; answers nothing for a position in one run and answers it in the next, and
;; an unanswered reference is stored as the same bare name as an unresolvable
;; one.
;;
;; Dispatch is synchronous -- running time is a freeze.
;;
;; The rules table is a `defvar': editing it leaves a loaded session alone.
;;
;; A running Emacs reads the deployed copy under ~/.emacs.d/lisp/, not the
;; working tree, and keeps functions this file no longer defines.  Load the
;; working tree to test it; run check-fresh-load.el before trusting a
;; deletion.
;;
;; This Emacs sets `lisp-indent-offset' to 4, so `indent-region' and the
;; apheleia formatter reindent this file away from its own style.  Bind it to
;; nil first.
;;
;; Measure with the tree's buffers killed, the server warm and the versions
;; interleaved.  Buffer and server state move a trace's wall clock more than
;; any change to this file does.

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

(defvar claude-code-ide-mcp--trace-visits nil
  "Buffers the trace running now reads its files through.
A cons of a file-to-buffer table and the list of buffers this trace opened,
which are the only ones it is allowed to close.")

(defmacro claude-code-ide-mcp--trace-with-visits (&rest body)
  "Run BODY with one buffer per file, shared by everything in it, then close.

The collector and the resolver read the same files, and putting a major mode
on one is a large part of a trace, so they share a buffer rather than moding
it twice.  `claude-code-ide-mcp--with-temp-visit' cannot: its buffer never
registers as visiting the file, so the resolver would not find it.

Closing is half the point -- the resolver used to leave a buffer open per
file it resolved through."
  (declare (indent 0) (debug t))
  `(let ((claude-code-ide-mcp--trace-visits
          (cons (make-hash-table :test 'equal) nil)))
     (unwind-protect (progn ,@body)
       (dolist (buffer (cdr claude-code-ide-mcp--trace-visits))
         (when (and (buffer-live-p buffer)
                    ;; Nothing here modifies a buffer, but killing a modified
                    ;; file-visiting one asks the user about saving it, and a
                    ;; tool call is no place to be asked.
                    (not (buffer-modified-p buffer)))
           (kill-buffer buffer))))))

(defun claude-code-ide-mcp--trace-visit (file)
  "Return a buffer visiting FILE, opening one for this trace if needed.
A buffer that already visits FILE is reused and left alone; one opened here
is registered with the trace, which closes it at the end.  Only run inside
`claude-code-ide-mcp--trace-with-visits'.

A real file-visiting buffer, so `find-buffer-visiting' finds it, but moded
without its hooks: eglot is asked for by name where it is wanted, and
copilot, flymake and dir-local reading are never wanted here."
  (let* ((table (car claude-code-ide-mcp--trace-visits))
         (known (and table (gethash file table))))
    (if (buffer-live-p known)
        known
      (let ((buffer
             (or (claude-code-ide-mcp--refresh-visiting file)
                 (let ((new (create-file-buffer file))
                       ;; A mode whose grammar and font-lock rules disagree
                       ;; logs its mismatch on every read.  The mismatch is
                       ;; real but not this tool's, and repeating it drowns
                       ;; the warning buffer.
                       (warning-suppress-log-types
                        (cons '(treesit-font-lock-rules-mismatch)
                              warning-suppress-log-types)))
                   (with-current-buffer new
                     ;; VISIT, so the file's modtime comes with its text and
                     ;; `verify-visited-file-modtime' does not revert on reuse.
                     (insert-file-contents file t)
                     (setq buffer-file-truename
                           (abbreviate-file-name (file-truename file)))
                     ;; `project-current' reads this, and eglot reads
                     ;; `project-current': without it the buffer keeps the
                     ;; caller's directory and Go files get asked of whatever
                     ;; server that project has.
                     (setq default-directory (file-name-directory file))
                     (delay-mode-hooks (set-auto-mode)))
                   (push new (cdr claude-code-ide-mcp--trace-visits))
                   new))))
        (when table (puthash file buffer table))
        buffer))))

(defun claude-code-ide-mcp--trace-known (store)
  "Return what STORE already holds, read in the order it was written.
The plist carries :nodes id to hash, :node-files, :node-unread and
:node-queries beside it, :edges by identity, :queries in the order they were
asked, and :scan, the last look at the tree.  A `gone' record removes the
node it names, which is why the file is replayed rather than scanned for the
newest line per id."
  (let ((nodes (make-hash-table :test 'equal))
        (node-files (make-hash-table :test 'equal))
        (node-lines (make-hash-table :test 'equal))
        (node-spans (make-hash-table :test 'equal))
        (node-uses (make-hash-table :test 'equal))
        (node-unread (make-hash-table :test 'equal))
        (node-queries (make-hash-table :test 'equal))
        (edges (make-hash-table :test 'equal))
        (edge-list '())
        (files (make-hash-table :test 'equal))
        (file-imports (make-hash-table :test 'equal))
        (queries '())
        (absent '())
        (retracted '())
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
                  (puthash id (plist-get rec :span) node-spans)
                  (puthash id (plist-get rec :uses) node-uses)
                  (puthash id (plist-get rec :unread) node-unread)
                  (puthash id (plist-get rec :q) node-queries))
                 ((equal kind "gone")
                  (remhash id nodes)
                  (remhash id node-files)
                  (remhash id node-lines)
                  (remhash id node-spans)
                  (remhash id node-uses)
                  (remhash id node-unread)
                  (remhash id node-queries))
                 ((equal kind "edge")
                  (unless (gethash (claude-code-ide-mcp--trace-edge-key rec) edges)
                    (push rec edge-list))
                  (puthash (claude-code-ide-mcp--trace-edge-key rec) t edges))
                 ((equal kind "absent") (push rec absent))
                 ((equal kind "retracted") (push (plist-get rec :claim) retracted))
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
          :node-spans node-spans
          :node-uses node-uses
          :node-unread node-unread
          :node-queries node-queries
          :edges edges
          :edge-list (nreverse edge-list)
          :files files
          :file-imports file-imports
          :queries (nreverse queries)
          ;; A retraction takes its absence out of the store's view: the
          ;; claim was that nothing matched, and the retraction says the
          ;; search behind it never ran.
          :absent (seq-remove (lambda (a) (member (plist-get a :claim) retracted))
                              (nreverse absent))
          :scan scan)))

(defun claude-code-ide-mcp--trace-parse (out)
  "Parse rg --vimgrep output OUT into a list of (FILE LINE . COL) match cells.
The shared parser drops the column; the column is what tells two calls on one
line apart.  COL is ripgrep's own: a one-based byte offset.

Sorted, because ripgrep's walkers are parallel and the block cap keeps a
prefix of whatever order they finished in."
  (let ((matches '()))
    (dolist (ln (split-string out "\n" t))
      (when (string-match "\\`\\(.*?\\):\\([0-9]+\\):\\([0-9]+\\):" ln)
        (push (cons (match-string 1 ln)
                    (cons (string-to-number (match-string 2 ln))
                          (string-to-number (match-string 3 ln))))
              matches)))
    (sort matches
          (lambda (a b)
            (let ((one (car a)) (two (car b)))
              (cond ((not (equal one two)) (string< one two))
                    ((/= (cadr a) (cadr b)) (< (cadr a) (cadr b)))
                    (t (< (cddr a) (cddr b)))))))))

(defun claude-code-ide-mcp--trace-search (pattern path)
  "Return (MATCHES . ERROR) for PATTERN under PATH.
ripgrep leaves with 1 when it matched nothing and with 2 when it could not
run the search at all -- an unbalanced paren in the pattern does that.  Both
produce no output, so a caller that reads only the output cannot tell a
proven absence from a search that never happened, and this tool exists to
keep those two apart."
  (let ((root (claude-code-ide-mcp--grep-block-root path))
        (status nil))
    (let ((out (with-output-to-string
                 (with-current-buffer standard-output
                   (setq status (call-process "rg" nil t nil
                                              "--vimgrep" "--" pattern root))))))
      (if (memq status '(0 1))
          (cons (claude-code-ide-mcp--trace-parse out) nil)
        (cons nil (string-trim (or out (format "rg exited with %s" status))))))))

(defun claude-code-ide-mcp--trace-file-hash (file)
  "Return the hash of FILE's bytes, or nil when it cannot be read."
  (when (file-readable-p file)
    (with-temp-buffer
      (set-buffer-multibyte nil)
      (insert-file-contents-literally file)
      (claude-code-ide-mcp--trace-hash (buffer-string)))))

(defun claude-code-ide-mcp--trace-append (store records)
  "Append RECORDS, one JSON object per line, to STORE.
`json-serialize' hands back UTF-8 bytes in a unibyte string, so the buffer
holding them is unibyte too and the write passes them through untouched.
Letting those bytes into a multibyte buffer instead turns each one into a raw
byte character, which no coding system will encode -- Emacs then stops and
asks the user which one to use, in the middle of a tool call."
  (make-directory (file-name-directory store) t)
  (with-temp-buffer
    (set-buffer-multibyte nil)
    (dolist (rec records)
      (insert (json-serialize rec) "\n"))
    (let ((coding-system-for-write 'binary))
      (write-region (point-min) (point-max) store t 'silent))))

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

(defun claude-code-ide-mcp--trace-match-position (line col)
  "Return the buffer position of the match at LINE and COL.
COL is ripgrep's column: a one-based count of bytes, not of characters, so a
line holding anything outside ASCII before the match lands short of it when
the number is added to a character position."
  (save-excursion
    (goto-char (point-min))
    (forward-line (1- line))
    (let ((pos (and (numberp col)
                    (ignore-errors
                      (byte-to-position (+ (position-bytes (point)) (1- col)))))))
      (min (max (or pos (progn (back-to-indentation) (point)))
                (line-beginning-position))
           (line-end-position)))))

(defun claude-code-ide-mcp--trace-statement-node (line col ceiling)
  "Return what the match at LINE and COL sits in, under CEILING, or nil.

Relations are read from this node rather than from CEILING, the block the
clone hash needs, so a match does not have every name of its enclosing
function read as if the seed had reached it.

A match in a declaration's signature is the declaration -- the holes and
types a signature declares are lost by stopping at one parameter.  Every
other match grows from its position to the first call, or to the last node
still below CEILING, whichever comes first.  All three rules earn their keep:
asking for the smallest node holding the whole line narrows nothing, since a
line in the middle of a multi-line call has no node below the block; growing
to a call or declaration alone leaves the body and takes the declaration,
which is wider than the block; and the column is what picks between two calls
written on one line."
  (let ((pos (claude-code-ide-mcp--trace-match-position line col)))
    (when-let* ((node (and (fboundp 'treesit-node-at)
                           (treesit-parser-list)
                           (save-excursion
                             (goto-char pos)
                             (treesit-node-at (point))))))
      (let ((decl (treesit-parent-until
                   node #'claude-code-ide-mcp--trace-declaration-p t)))
        (if (and decl (< pos (claude-code-ide-mcp--trace-signature-end decl)))
            decl
          (or (treesit-parent-until
               node
               (lambda (n)
                 (and (treesit-node-check n 'named)
                      (treesit-node-parent n)
                      (or (treesit-node-child-by-field-name n "arguments")
                          (and ceiling
                               (treesit-node-eq (treesit-node-parent n)
                                                ceiling)))))
               t)
              node))))))

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
the ones NODE actually mentions.

The record carries no `:unread': coverage is only known once every match in
the file has been read, so the collector adds that field itself."
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
          ;; A locator, never an identity: not in the id, not in the hash,
          ;; never compared.  Lines move under edits the hash cannot see.
          :line (line-number-at-pos (treesit-node-start node))
          ;; How much code the node covers.  The clone answer orders by this,
          ;; since a block that grew no further than the matched line is
          ;; identical to every other such block by construction.
          :span (1+ (- (line-number-at-pos (treesit-node-end node))
                       (line-number-at-pos (treesit-node-start node))))
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

(defconst claude-code-ide-mcp--trace-call-search-depth 3
  "How far above a called name the call expression may sit.")

(defun claude-code-ide-mcp--trace-rules ()
  "Return the language rules for the current buffer's mode."
  (alist-get major-mode claude-code-ide-mcp-trace-language-rules))

(defvar claude-code-ide-mcp--trace-feature-cache nil
  "Font-lock captures per feature for the file being read right now.
Each query runs from the tree's root however small the region asked for, so
asking once per node made the cost of a file quadratic in the nodes it held.
Reading the file once and looking up afterwards removes that.

The binding lasts one file and no longer, on purpose.  Keeping it on the
buffer would leave it behind in whatever the user has open, where the next
trace would answer from captures taken before their last edit -- the same run
would then report different edges depending on which buffers happened to be
alive.  A cache that changes the answer is worse than no cache.")

(defvar claude-code-ide-mcp--trace-declaration-cache nil
  "Declaration ids already built for the file being read right now.
Several registering calls share one enclosing declaration, and describing it
means normalizing its whole text, so it is described once.  Scoped to a
single file for the same reason as the capture cache.")

(defmacro claude-code-ide-mcp--trace-with-feature-cache (&rest body)
  "Run BODY with fresh per-file caches for captures and declaration ids."
  (declare (indent 0) (debug t))
  `(let ((claude-code-ide-mcp--trace-feature-cache (make-hash-table :test 'eq))
         (claude-code-ide-mcp--trace-declaration-cache
          (make-hash-table :test 'equal)))
     ,@body))

(defun claude-code-ide-mcp--trace-feature-all (feature)
  "Return every node FEATURE's font-lock query captures in this buffer."
  (let ((hit (and claude-code-ide-mcp--trace-feature-cache
                  (gethash feature claude-code-ide-mcp--trace-feature-cache 'miss))))
    (if (and hit (not (eq hit 'miss)))
        hit
      (let ((out '()))
        (dolist (setting treesit-font-lock-settings)
          (when (eq (nth 2 setting) feature)
            ;; The region is given even though it is the whole buffer.
            ;; Omitting it does not mean "everything": the same query over
            ;; the same tree returns fewer captures with no region than with
            ;; one spanning the file, and the ones it drops are silent.
            (dolist (capture (ignore-errors
                               (treesit-query-capture
                                (treesit-buffer-root-node) (nth 0 setting)
                                (point-min) (point-max))))
              (push (cdr capture) out))))
        (setq out (vconcat (sort out (lambda (a b) (< (treesit-node-start a)
                                                      (treesit-node-start b))))))
        (when claude-code-ide-mcp--trace-feature-cache
          (puthash feature out claude-code-ide-mcp--trace-feature-cache))
        out))))

(defun claude-code-ide-mcp--trace-feature-lower-bound (nodes beg)
  "Return the first index in NODES whose node starts at or after BEG."
  (let ((low 0)
        (high (length nodes)))
    (while (< low high)
      (let ((mid (/ (+ low high) 2)))
        (if (< (treesit-node-start (aref nodes mid)) beg)
            (setq low (1+ mid))
          (setq high mid))))
    low))

(defun claude-code-ide-mcp--trace-feature-nodes (feature beg end)
  "Return the nodes FEATURE's own font-lock query captures between BEG and END.
Font-lock feature names are shared across tree-sitter modes, so asking the
mode which tokens are calls, types or attributes routes the search without
this file naming any grammar's node types.  The region is applied here rather
than passed to the query, which bounds the patterns it tries and not the
captures it returns -- a chain of calls needs each link read on its own.

The captures are held sorted so a region is found by bisection.  Walking all
of them per question made edge extraction the slowest part of a trace: it is
asked once per call, and a file's calls are proportional to its captures."
  (let* ((nodes (claude-code-ide-mcp--trace-feature-all feature))
         (i (claude-code-ide-mcp--trace-feature-lower-bound nodes beg))
         (total (length nodes))
         (out '()))
    (while (and (< i total) (<= (treesit-node-start (aref nodes i)) end))
      (let ((node (aref nodes i)))
        (when (<= (treesit-node-end node) end)
          (push node out)))
      (setq i (1+ i)))
    (nreverse out)))

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
  "Return an endpoint plist naming NODE's text and where it sits.
The column counts characters from the start of the line.  `current-column'
counts display columns, which is not what the server is asked for and not
what a tab is worth."
  (list :name (treesit-node-text node t)
        :file (buffer-file-name)
        :line (line-number-at-pos (treesit-node-start node))
        :col (save-excursion
               (goto-char (treesit-node-start node))
               (- (point) (line-beginning-position)))))

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

(defun claude-code-ide-mcp--trace-register-entry (call)
  "Return the rules entry for CALL when it registers something, else nil.
Asked before anything is built for CALL: nearly every call in a file
registers nothing, and finding that out has to be cheaper than describing the
declaration the call sits in."
  (when-let* ((method (claude-code-ide-mcp--trace-callee-name call)))
    (assoc (treesit-node-text method t)
           (plist-get (claude-code-ide-mcp--trace-rules) :register))))

(defun claude-code-ide-mcp--trace-register-edges (call entry from-id box)
  "Collect what CALL registers, sourced at FROM-ID, into BOX.
ENTRY is CALL's rules entry, from `claude-code-ide-mcp--trace-register-entry'."
  (let* ((args (claude-code-ide-mcp--trace-named-children
                (treesit-node-child-by-field-name call "arguments")))
         (registered (nthcdr (cdr entry) args)))
    (dolist (arg registered)
      (dolist (base (claude-code-ide-mcp--trace-peel arg box))
        (push (list :kind "registers"
                    :from (list :id from-id)
                    :to (claude-code-ide-mcp--trace-ref base))
              (car box))))
    t))

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

(defun claude-code-ide-mcp--trace-relation-end (node)
  "Return where NODE's own relations stop.
For a declaration that is the end of its signature: what it declares is the
holes, their types and the name it binds, while what its body does belongs
to the blocks inside it, which are nodes of their own.  Without this a match
on a signature line reads the whole function as relations of the signature."
  (if (claude-code-ide-mcp--trace-declaration-p node)
      (claude-code-ide-mcp--trace-signature-end node)
    (treesit-node-end node)))

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
                     'function (treesit-node-start node)
                     (claude-code-ide-mcp--trace-relation-end node)))
        (when-let* ((call (claude-code-ide-mcp--trace-call-of name)))
          (remember call)))
      ;; Upward only as far as the call that directly holds NODE.  Walking to
      ;; the root instead hands back every call the statement is nested in,
      ;; and reading their arguments pulls in the whole of an enclosing
      ;; expression -- one test function came back as 239 relations that way,
      ;; about code the seed never matched.
      (let ((cur (treesit-node-parent node))
            (depth 0))
        (while (and cur (< depth claude-code-ide-mcp--trace-call-search-depth))
          (when (treesit-node-child-by-field-name cur "arguments")
            (remember cur)
            (setq cur nil))
          (when cur
            (setq cur (treesit-node-parent cur))
            (setq depth (1+ depth))))))
    (nreverse out)))

(defun claude-code-ide-mcp--trace-declaration-id (decl root query-id imports nodes)
  "Return DECL's node id under ROOT, recording DECL as a node in NODES.
An edge starting at a declaration is the answer to \"who registers this\", and
an answer nobody can open is half an answer, so the declaration is stored with
its own line rather than left as a name the store knows nothing else about."
  ;; Keyed on both ends.  A declaration and something that starts where it
  ;; starts are different nodes, and letting one answer for the other would
  ;; hand back an id that belongs to neither.
  (let ((key (cons (treesit-node-start decl) (treesit-node-end decl)))
        (cache claude-code-ide-mcp--trace-declaration-cache))
    (or (and cache (gethash key cache))
        (let* ((text (claude-code-ide-mcp--trace-normalized-text decl))
               (record (claude-code-ide-mcp--trace-node-record
                        (buffer-file-name) root decl query-id text imports))
               (id (plist-get record :id)))
          (unless (string-empty-p text)
            (push record (car nodes)))
          (when cache (puthash key id cache))
          id))))

(defun claude-code-ide-mcp--trace-decl-kind (name)
  "Return what kind of declaration NAME declares, as the grammar names it."
  (when-let* ((parent (treesit-node-parent name)))
    (treesit-node-type parent)))

(defun claude-code-ide-mcp--trace-decls-in (node)
  "Return the declarations NODE encloses as (NAME-NODE . KIND), in order.
KIND is the enclosing node's own type -- the grammar saying what was
declared, rather than this file guessing from a list of names."
  (mapcar (lambda (name)
            (cons name (claude-code-ide-mcp--trace-decl-kind name)))
          (claude-code-ide-mcp--trace-feature-nodes
           'definition (treesit-node-start node) (treesit-node-end node))))

(defun claude-code-ide-mcp--trace-parameter-names (decl)
  "Return DECL's own parameters in order, as (INDEX . NAME-NODE).
These are the holes a call fills.  Only DECL's own parameter list counts:
reading every parameter inside the declaration would number a closure's
arguments among the function's, and an argument filling hole 3 would be
pointed at a hole belonging to a lambda three lines in."
  (when-let* ((holes (treesit-node-child-by-field-name decl "parameters")))
    (let ((i -1))
      (mapcar (lambda (name) (cons (setq i (1+ i)) name))
              (claude-code-ide-mcp--trace-feature-nodes
               'definition (treesit-node-start holes) (treesit-node-end holes))))))

(defun claude-code-ide-mcp--trace-call-arguments (call)
  "Return CALL's arguments in order, as (INDEX . NODE)."
  (let ((i -1))
    (mapcar (lambda (arg) (cons (setq i (1+ i)) arg))
            (claude-code-ide-mcp--trace-named-children
             (treesit-node-child-by-field-name call "arguments")))))

(defun claude-code-ide-mcp--trace-uses-in (node)
  "Return the use sites NODE encloses as (NAME-NODE . ROLE), in order.
ROLE is the font-lock feature that marked it -- a call, a type, a variable or
a property.  Every relation in the language graph starts at one of these."
  (let ((out '()))
    (dolist (role '(function type variable property))
      (dolist (name (claude-code-ide-mcp--trace-feature-nodes
                     role (treesit-node-start node)
                     (claude-code-ide-mcp--trace-relation-end node)))
        (push (cons name role) out)))
    (sort out (lambda (a b) (< (treesit-node-start (car a))
                               (treesit-node-start (car b)))))))

(defun claude-code-ide-mcp--trace-unread-names (node covered)
  "Return the names inside NODE that no span in COVERED holds.
COVERED is a list of (START . END), the statements this trace read relations
from.  A name outside all of them is one the seed never reached: naming it
costs a string, following it costs a server round trip, and saying nothing
about it would let a node carrying three lines' relations read as a node with
nothing more in it.

Only calls and types count, since those are what the `ref' edge records."
  (let ((seen (make-hash-table :test 'equal))
        (out '()))
    (dolist (role '(function type))
      (dolist (name (claude-code-ide-mcp--trace-feature-nodes
                     role (treesit-node-start node) (treesit-node-end node)))
        (let ((start (treesit-node-start name))
              (end (treesit-node-end name)))
          (when (and (claude-code-ide-mcp--trace-name-node-p name)
                     (not (seq-find (lambda (span)
                                      (and (>= start (car span))
                                           (<= end (cdr span))))
                                    covered)))
            (let ((text (treesit-node-text name t)))
              (unless (gethash text seen)
                (puthash text t seen)
                (push text out)))))))
    (nreverse out)))

(defun claude-code-ide-mcp--trace-leaves-scope-p (name calls)
  "Non-nil when NAME sits in an argument of one of CALLS.
A reference that is handed to a call reaches another declaration, and that is
what makes it worth storing.  One that begins and ends inside the same scope
is recoverable by reading that scope again."
  (let ((start (treesit-node-start name))
        (end (treesit-node-end name))
        (out nil))
    (dolist (call calls)
      (unless out
        (when-let* ((args (treesit-node-child-by-field-name call "arguments")))
          (when (and (>= start (treesit-node-start args))
                     (<= end (treesit-node-end args)))
            (setq out t)))))
    out))

(defun claude-code-ide-mcp--trace-language-edges (node record calls box local-scope)
  "Collect the language relations NODE takes part in, into BOX.

Three kinds, none of them an interpretation: `contains' for a declaration
holding a hole, `arg' for a value filling one, and `ref' for a use naming
something.  A framework reading -- that a call registers, that an attribute
requires -- is derived from these afterwards, so the reading always has the
fact it came from underneath it.

CALLS are the calls around NODE, already found.  LOCAL-SCOPE keeps the
references that never leave their own scope; without it only the ones that
reach past it are written."
  (let ((from-id (plist-get record :id)))
    (when (claude-code-ide-mcp--trace-declaration-p node)
      (dolist (hole (claude-code-ide-mcp--trace-parameter-names node))
        (push (list :kind "contains"
                    :from (list :id from-id)
                    :to (claude-code-ide-mcp--trace-ref (cdr hole))
                    :at (format "param%d" (car hole)))
              (car box))))
    (dolist (call calls)
      (when-let* ((callee (claude-code-ide-mcp--trace-callee-name call)))
        (dolist (arg (claude-code-ide-mcp--trace-call-arguments call))
          ;; The argument is peeled to the names it carries.  Left whole, an
          ;; endpoint would be a multi-line expression rather than something
          ;; the graph can point at, and the ordering calls wrapped around it
          ;; would go unrecorded.
          (dolist (base (claude-code-ide-mcp--trace-peel (cdr arg) box))
            (push (list :kind "arg"
                        :from (claude-code-ide-mcp--trace-ref callee)
                        :to (claude-code-ide-mcp--trace-ref base)
                        :at (format "arg%d" (car arg)))
                  (car box))))))
    (dolist (use (claude-code-ide-mcp--trace-uses-in node))
      (when (or local-scope
                (memq (cdr use) '(function type))
                (claude-code-ide-mcp--trace-leaves-scope-p (car use) calls))
        (push (list :kind "ref"
                    :from (list :id from-id)
                    :to (claude-code-ide-mcp--trace-ref (car use))
                    :at (symbol-name (cdr use)))
              (car box))))))

(defun claude-code-ide-mcp--trace-edges-at (node record attributes root query-id
                                                 box nodes imports local-scope)
  "Collect the relations NODE takes part in, given its RECORD, into BOX.
The language graph is written first and framework readings are layered on it.
ATTRIBUTES holds the file's attributes by owner, ROOT is the project root,
QUERY-ID names the query, and LOCAL-SCOPE keeps scope-bound references."
  (let ((calls (claude-code-ide-mcp--trace-calls-around node)))
    (claude-code-ide-mcp--trace-language-edges node record calls box local-scope)
    (dolist (call calls)
      (when-let* ((entry (claude-code-ide-mcp--trace-register-entry call)))
        (claude-code-ide-mcp--trace-register-edges
         call entry
         (claude-code-ide-mcp--trace-declaration-id
          (or (claude-code-ide-mcp--trace-declaration call) call)
          root query-id imports nodes)
         box))))
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

(defun claude-code-ide-mcp--trace-collect (matches root query-id &optional local-scope)
  "Turn MATCHES, a list of (FILE LINE . COL), into node records under ROOT.
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
     (lambda (file ats)
       (let ((inhibit-redisplay t))
         (with-current-buffer (claude-code-ide-mcp--trace-visit file)
           (claude-code-ide-mcp--trace-with-feature-cache
           (save-excursion
             (let* ((seen (make-hash-table :test 'equal))
                    (covered (make-hash-table :test 'equal))
                    (blocks '())
                    (attributes (claude-code-ide-mcp--trace-attribute-table))
                    (imports (claude-code-ide-mcp--trace-import-names)))
               (push (list :k "file"
                           :path (file-relative-name file root)
                           :hash (claude-code-ide-mcp--trace-file-hash file)
                           :imports (vconcat imports)
                           :at (format-time-string "%FT%T%z"))
                     seen-files)
               ;; By line and then column: the cells arrive reversed from the
               ;; push above, and a sort on the line alone is stable, so two
               ;; matches on one line would be read right to left.
               (dolist (at (sort (copy-sequence ats)
                                 (lambda (a b)
                                   (or (< (car a) (car b))
                                       (and (= (car a) (car b))
                                            (< (cdr a) (cdr b)))))))
                 (let ((line (car at))
                       (col (cdr at)))
                   (if-let* ((node (claude-code-ide-mcp--trace-block-node line)))
                       (let* ((key (cons (treesit-node-start node)
                                         (treesit-node-end node)))
                              (record (gethash key seen)))
                         (unless record
                           (let ((text (claude-code-ide-mcp--trace-normalized-text
                                        node)))
                             (if (string-empty-p text)
                                 (progn (setq empty (1+ empty))
                                        (puthash key 'empty seen))
                               (setq record (claude-code-ide-mcp--trace-node-record
                                             file root node query-id text
                                             imports))
                               (puthash key record seen)
                               (push (list key node record) blocks))))
                         ;; Every match reads its own statement, including one
                         ;; whose block another match recorded: two calls in a
                         ;; block are two questions.  Repeats go in
                         ;; `claude-code-ide-mcp--trace-dedupe-edges'.
                         (unless (or (null record) (eq record 'empty))
                           (let ((inner (or (claude-code-ide-mcp--trace-statement-node
                                             line col node)
                                            node)))
                             ;; Covered is the range relations were read from,
                             ;; which for a declaration stops at its signature.
                             (push (cons (treesit-node-start inner)
                                         (claude-code-ide-mcp--trace-relation-end
                                          inner))
                                   (gethash key covered))
                             (ignore-errors
                               (claude-code-ide-mcp--trace-edges-at
                                inner record attributes root query-id box
                                node-box imports local-scope)))))
                     (setq unparsed (1+ unparsed)))))
               ;; Coverage is only known once every match in the file has been
               ;; read, so the records are finished here, not where built.
               (dolist (cell (nreverse blocks))
                 (push (append (nth 2 cell)
                               (list :unread
                                     (vconcat
                                      (claude-code-ide-mcp--trace-unread-names
                                       (nth 1 cell)
                                       (gethash (nth 0 cell) covered)))))
                       records))))))))
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
      ;; The trace's own search, not the shared one: the collector reads a
      ;; match as (FILE LINE . COL) and takes its boundary from the column,
      ;; which the shared parser throws away.
      (let* ((matches (car (claude-code-ide-mcp--trace-search
                            (plist-get query :pattern) file)))
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

(defun claude-code-ide-mcp--trace-definitions-in (file positions)
  "Ask the server what FILE's POSITIONS define, in one visit to FILE.
POSITIONS are (LINE . COL) cells; the answer is a table from each of them to
a (TARGET-FILE . TARGET-LINE) pair, with the positions the server would not
answer simply absent.

The server is asked at the reference itself rather than by name, since a name
query cannot tell a definition from a re-export of it.  That is one request
per reference and unavoidable; one buffer visit per reference is not, and is
what this exists to avoid -- the file is visited, checked and named once.

Positions are sorted and walked forward: the caller's order is a string sort,
and the line is carried along because `line-number-at-pos' counts from the
start of the buffer on every call.  A request that errors leaves its position
out; a quit travels, because the caller reads it as the interruption it is."
  (let ((out (make-hash-table :test 'equal))
        (inhibit-redisplay t))
    (claude-code-ide-mcp-server-with-session-context nil
      (with-current-buffer (claude-code-ide-mcp--trace-visit file)
        (when-let* ((server (claude-code-ide-mcp--ensure-eglot file))
                    (uri (eglot-path-to-uri (buffer-file-name))))
          (save-excursion
            (goto-char (point-min))
            (let ((here 1))
              (dolist (pos (sort (copy-sequence positions)
                                 (lambda (a b)
                                   (or (< (car a) (car b))
                                       (and (= (car a) (car b))
                                            (< (cdr a) (cdr b)))))))
                (forward-line (- (car pos) here))
                (setq here (car pos))
                (goto-char (min (+ (line-beginning-position) (cdr pos))
                                (line-end-position)))
                (when-let*
                    ((raw (condition-case nil
                              (eglot--request
                               server :textDocument/definition
                               (list :textDocument (list :uri uri)
                                     ;; eglot's conversion: the protocol
                                     ;; counts UTF-16 code units.
                                     :position (eglot--pos-to-lsp-position
                                                (point)))
                               :timeout 10)
                            (error nil)))
                   (hit (cond ((vectorp raw) (and (> (length raw) 0) (aref raw 0)))
                              ((null raw) nil)
                              (t raw)))
                   (target (or (plist-get hit :targetUri) (plist-get hit :uri)))
                   (range (or (plist-get hit :targetSelectionRange)
                              (plist-get hit :targetRange)
                              (plist-get hit :range))))
                  (puthash pos
                           (cons (claude-code-ide-mcp--trace-uri-to-path target)
                                 (1+ (plist-get (plist-get range :start) :line)))
                           out))))))))
    out))

(defun claude-code-ide-mcp--trace-declaration-records-at (file lines root query-id)
  "Return a table of LINE to declaration record for FILE, visiting it once.
Endpoints cluster: a few hundred references resolve to a few dozen files, and
opening one of those per reference was the slowest thing a trace did.  The
lines wanted from a file are answered in a single visit."
  (let ((out (make-hash-table :test 'eql)))
    (when (and file (file-readable-p file))
      (let ((inhibit-redisplay t))
        (with-current-buffer (claude-code-ide-mcp--trace-visit file)
          (claude-code-ide-mcp--trace-with-feature-cache
            ;; The imports are read here too.  Two producers build a record
            ;; for the same declaration -- this one and the edge source -- and
            ;; if only one of them knows the file's imports, the node's `uses'
            ;; flips between runs and every run reports it as context-changed
            ;; while nothing has changed at all.
            (let ((imports (claude-code-ide-mcp--trace-import-names)))
              (dolist (line (delete-dups (copy-sequence lines)))
                (save-excursion
                  (goto-char (point-min))
                  (forward-line (1- line))
                  (back-to-indentation)
                  (when-let* ((node (and (treesit-parser-list)
                                         (treesit-node-at (point))))
                              (decl (claude-code-ide-mcp--trace-declaration node))
                              (text (claude-code-ide-mcp--trace-normalized-text decl)))
                    (unless (string-empty-p text)
                      (puthash line
                               (claude-code-ide-mcp--trace-node-record
                                file root decl query-id text imports)
                               out))))))))))
    out))

(defun claude-code-ide-mcp--trace-reference-key (endpoint)
  "Return the identity of ENDPOINT as a reference position."
  (format "%s|%s|%s"
          (plist-get endpoint :file)
          (plist-get endpoint :line)
          (plist-get endpoint :col)))

(defun claude-code-ide-mcp--trace-references (edges)
  "Return the distinct unresolved endpoints of EDGES, in the order met."
  (let ((seen (make-hash-table :test 'equal))
        (order '()))
    (dolist (edge edges)
      (dolist (side '(:from :to))
        (let ((end (plist-get edge side)))
          (unless (plist-get end :id)
            (let ((key (claude-code-ide-mcp--trace-reference-key end)))
              (unless (gethash key seen)
                (puthash key end seen)
                (push key order)))))))
    ;; Sorted, because the file cap decides which references get resolved by
    ;; taking them in order, and the order the edges arrive in comes from a
    ;; hash table.  Leaving it there makes two runs of the same trace resolve
    ;; different endpoints and report different edges.
    (cons seen (sort (nreverse order) #'string<))))

(defun claude-code-ide-mcp--trace-edge-record (edge from to query-id)
  "Return the store record for EDGE running FROM to TO, found by QUERY-ID.
An endpoint whose kind is \"name\" is one the server would not resolve, and
saying so is the point: an unresolved endpoint must not read as a resolved
one."
  (let ((record (list :k "edge"
                      :kind (plist-get edge :kind)
                      :from (car from)
                      :from_kind (cdr from)
                      :to (car to)
                      :to_kind (cdr to)
                      :ev "treesit"
                      :q query-id)))
    ;; Where the reference sits -- which argument, which parameter, which
    ;; font-lock role marked it.  A relation without it says that two things
    ;; are connected; with it, a later reading can say how.
    (if (plist-get edge :at)
        (append record (list :at (plist-get edge :at)))
      record)))

(defun claude-code-ide-mcp--trace-resolve (edges root query-id)
  "Resolve the endpoints of EDGES under ROOT, as found by QUERY-ID.
Returns a plist of the edge records, the target nodes resolving them turned
up, and what the resolution cost.

The work runs in two passes on purpose.  Asking the server where a reference
leads is cheap; describing what lives there means opening that file, and
references cluster hard onto a few targets.  So every reference is located
first, then each target file is opened once for all the lines wanted from it.

Resolution is also the part a person can interrupt -- by pressing C-g, or by
editing the buffer under a request, which eglot reports as a quit of its own.
Neither throws the trace away: the blocks are already collected, the answer is
already computable, and an endpoint nobody got to resolve is exactly the
\"name\" case the schema already carries."
  (let* ((found (claude-code-ide-mcp--trace-references edges))
         (refs (car found))
         (order (cdr found))
         (locations (make-hash-table :test 'equal))
         (visited (make-hash-table :test 'equal))
         (records (make-hash-table :test 'equal))
         (nodes '())
         (stopped nil))
    ;; Both passes sit under the handler.  Reading a target file can fail or
    ;; be interrupted exactly like asking the server can, and stopping there
    ;; must leave the remaining endpoints as the names they already are
    ;; rather than throwing away a trace whose blocks are all collected.
    (condition-case nil
        (progn
          ;; Grouped by the file the reference sits in: that file is opened,
          ;; checked and named once instead of once per reference.
          (let ((by-source (make-hash-table :test 'equal))
                (sources '()))
            (dolist (key order)
              (let* ((end (gethash key refs))
                     (file (plist-get end :file)))
                (unless (gethash file by-source) (push file sources))
                (push (cons key (cons (plist-get end :line) (plist-get end :col)))
                      (gethash file by-source))))
            (dolist (file (nreverse sources))
              (puthash file t visited)
              (let* ((cells (nreverse (gethash file by-source)))
                     (found (claude-code-ide-mcp--trace-definitions-in
                             file (mapcar #'cdr cells))))
                (dolist (cell cells)
                  (let ((loc (gethash (cdr cell) found)))
                    (puthash (car cell)
                             (cond
                              ((null loc) nil)
                              ;; A definition outside the project is real but
                              ;; not this graph's to hold: a node id reaching
                              ;; into a package cache would key on a path that
                              ;; changes with every upgrade.
                              ((not (string-prefix-p root
                                                     (expand-file-name (car loc))))
                               'external)
                              (t loc))
                             locations))))))
          (let ((by-file (make-hash-table :test 'equal)))
            (maphash (lambda (_key loc)
                       (when (consp loc)
                         (push (cdr loc) (gethash (car loc) by-file))))
                     locations)
            (maphash (lambda (file lines)
                       (maphash (lambda (line record)
                                  (puthash (format "%s|%s" file line)
                                           record records)
                                  (push record nodes))
                                (claude-code-ide-mcp--trace-declaration-records-at
                                 file lines root query-id)))
                     by-file)))
      (quit (setq stopped t))
      (error (setq stopped t)))
    (cl-labels
        ((endpoint (end)
           (if (plist-get end :id)
               (cons (plist-get end :id) "node")
             (let ((loc (gethash (claude-code-ide-mcp--trace-reference-key end)
                                 locations))
                   (name (plist-get end :name)))
               (cond
                ((eq loc 'external) (cons name "external"))
                ((consp loc)
                 (let ((record (gethash (format "%s|%s" (car loc) (cdr loc))
                                        records)))
                   (if record (cons (plist-get record :id) "node")
                     (cons name "name"))))
                (t (cons name "name")))))))
      (let ((out '()))
        (dolist (edge edges)
          (push (claude-code-ide-mcp--trace-edge-record
                 edge
                 (endpoint (plist-get edge :from))
                 (endpoint (plist-get edge :to))
                 query-id)
                out))
        (let* ((recs (nreverse out))
               (left (seq-count (lambda (e)
                                  (or (equal (plist-get e :from_kind) "name")
                                      (equal (plist-get e :to_kind) "name")))
                                recs)))
          (list :stopped stopped
                ;; Counted over the edges, not over the references asked: an
                ;; interrupted run has to say how much of the answer is still
                ;; a bare name, and a reference count cannot say that.
                :left (if stopped left 0)
                :edges recs
                :nodes nodes
                :files (hash-table-count visited)
                :unresolved (seq-count
                             (lambda (e) (equal (plist-get e :to_kind) "name"))
                             recs)))))))

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

(defun claude-code-ide-mcp--trace-merge-unread (records known)
  "Return RECORDS with each :unread reconciled against what KNOWN holds.
The intersection of what this run left unread with what the store left
unread is what nobody has followed, so the field only ever shrinks.  A
changed hash means the stored list is about other text, and this run's answer
stands alone.

A record that measured nothing inherits the stored list instead.  Coverage
belongs to the node, not to the producer that happened to write it: the same
id arrives as a block one run and as the far end of an edge the next, and
only the block reads what it holds.  Without this the endpoint is classified
as a change, written back without the field, and the node reads unmeasured
from then on."
  (mapcar
   (lambda (rec)
     (let* ((id (plist-get rec :id))
            (mine (plist-get rec :unread))
            (theirs (gethash id (plist-get known :node-unread)))
            (same (equal (gethash id (plist-get known :nodes))
                         (plist-get rec :hash))))
       (cond
        ((not (and theirs same)) rec)
        (mine (plist-put (copy-sequence rec)
                         :unread
                         (vconcat (seq-intersection (append mine nil)
                                                    (append theirs nil)))))
        (t (plist-put (copy-sequence rec) :unread theirs)))))
   records))

(defun claude-code-ide-mcp--trace-classify (records known changed-imports)
  "Split RECORDS against what KNOWN holds, given CHANGED-IMPORTS by file.
Returns a plist of :new :changed :context :moved and :unchanged record lists.

A `context' node is what this mechanism exists for: its text is untouched, so
its hash agrees, but an import it names now resolves elsewhere, and calling
it unchanged would be a lie about meaning.  A `moved' node is the same code
in a different place, or with less of it left unread; it is written back
quietly so the locator and the coverage keep up."
  (let ((hashes (plist-get known :nodes))
        (lines (plist-get known :node-lines))
        (uses (plist-get known :node-uses))
        (unread (plist-get known :node-unread))
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
                   ;; A record written before the span existed cannot answer
                   ;; how much code it covers, and the clone answer orders by
                   ;; exactly that, so it is quietly written back with one.
                   (null (gethash id (plist-get known :node-spans)))
                   (not (equal (gethash id lines) (plist-get rec :line)))
                   ;; Presence first, contents second.  An empty vector and an
                   ;; absent field both flatten to nil, and they mean
                   ;; different things: measured with nothing left, against
                   ;; never measured.
                   (not (eq (null (gethash id unread))
                            (null (plist-get rec :unread))))
                   (not (equal (append (gethash id unread) nil)
                               (append (plist-get rec :unread) nil))))
               (push rec moved))
              (t (push rec unchanged)))))
    (list :new (nreverse new)
          :changed (nreverse changed)
          :context (nreverse context)
          :moved (nreverse moved)
          :unchanged (nreverse unchanged))))

(defun claude-code-ide-mcp--trace-group-span (group)
  "Return how many lines GROUP's blocks cover, or 1 when they do not say."
  (or (plist-get (car (cdr group)) :span) 1))

(defun claude-code-ide-mcp--trace-clone-groups (records)
  "Group RECORDS by content hash, widest group first, singletons dropped.

Ordered by how much code each duplicate covers rather than by how many of
them there are.  Counting members puts the seed at the top: it is a literal,
so every block that grew no further than the matched line matches every other
one, and nine copies of the line that was searched for outranks two copies of
a twenty-line function.  The first is a restatement of the question and the
second is the answer."
  (let ((by-hash (make-hash-table :test 'equal))
        (groups '()))
    (dolist (rec records)
      (push rec (gethash (plist-get rec :hash) by-hash)))
    (maphash (lambda (hash recs)
               (when (cdr recs)
                 (push (cons hash (nreverse recs)) groups)))
             by-hash)
    (sort groups
          (lambda (a b)
            (let ((sa (claude-code-ide-mcp--trace-group-span a))
                  (sb (claude-code-ide-mcp--trace-group-span b)))
              (if (= sa sb)
                  (> (length (cdr a)) (length (cdr b)))
                (> sa sb)))))))

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
                 (let ((span (claude-code-ide-mcp--trace-group-span group)))
                   (format "  #%s  %dx  %s  %s%s\n"
                           (car group) (length (cdr group))
                           (format "%d lines" span)
                           (string-join
                            (delete-dups (mapcar (lambda (r) (plist-get r :kind))
                                                 (cdr group)))
                            "/")
                           (concat "  "
                                   (mapconcat (lambda (r) (plist-get r :id))
                                              (cdr group) "  ")))))
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

(defconst claude-code-ide-mcp--trace-unread-nodes-shown 10
  "How many nodes with unfollowed names one trace report lists by name.")

(defconst claude-code-ide-mcp--trace-unread-names-shown 8
  "How many of a node's unfollowed names one trace report prints.")

(defun claude-code-ide-mcp--trace-render-unread (records)
  "Render what RECORDS name inside themselves and nobody has followed.
Printing it is what keeps the rest of the answer from reading as the whole."
  (let* ((left (seq-filter (lambda (rec) (> (length (plist-get rec :unread)) 0))
                           records))
         (names (apply #'+ (mapcar (lambda (rec) (length (plist-get rec :unread)))
                                   left))))
    (if (null left)
        ""
      (format "unread: %d names in %d of these blocks, never followed -- seed one of them to go a hop further\n%s"
              names (length left)
              (mapconcat
               (lambda (rec)
                 (let ((held (append (plist-get rec :unread) nil)))
                   (format "  %s  %s%s\n"
                           (plist-get rec :id)
                           (string-join
                            (seq-take held
                                      claude-code-ide-mcp--trace-unread-names-shown)
                            " ")
                           (if (> (length held)
                                  claude-code-ide-mcp--trace-unread-names-shown)
                               (format " +%d"
                                       (- (length held)
                                          claude-code-ide-mcp--trace-unread-names-shown))
                             ""))))
               (seq-take (seq-sort-by (lambda (rec) (length (plist-get rec :unread)))
                                      #'> left)
                         claude-code-ide-mcp--trace-unread-nodes-shown)
               "")))))

(defun claude-code-ide-mcp--trace-render (records counts query store
                                                  collected resolved fresh-edges
                                                  refreshed)
  "Render the whole trace report.
RECORDS are the node records, COUNTS the plist from
`claude-code-ide-mcp--trace-classify', QUERY the query record, STORE the
store path, COLLECTED the plist from `claude-code-ide-mcp--trace-collect',
RESOLVED the plist from `claude-code-ide-mcp--trace-resolve' and FRESH-EDGES
those it added."
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
   (format "frontier: %d matches with no tree-sitter block, %d comment-only blocks, %d files put under the language server%s\n"
           (plist-get collected :unparsed)
           (plist-get collected :empty)
           (plist-get resolved :files)
           (if (plist-get resolved :stopped)
               (format ", resolution stopped with %d endpoints left as names -- the blocks and the answer above are complete"
                       (plist-get resolved :left))
             ""))
   (claude-code-ide-mcp--trace-render-unread records)))

(defun claude-code-ide-mcp-trace (pattern &optional path cap ask local_scope)
  "Trace PATTERN through the project and record what it finds as graph nodes.
Every hit grows to its enclosing tree-sitter block, which becomes a node
identified by file, declaration path and, for a block below a declaration,
its position within it -- never a line number.  Each node is stamped with a
hash of its text after comments and whitespace are removed, so blocks sharing
a hash are clones however they are named.  New and changed nodes are
appended to the project's JSONL store, and the report states how many, so the
caller never has to take the write on trust.  PATH narrows the search root,
CAP bounds the blocks examined (default 200, 0 = unlimited) and ASK records
the question this query answers.  LOCAL_SCOPE keeps the references that never
leave the scope they sit in."
  (condition-case err
      (claude-code-ide-mcp--trace-with-visits
        (let* ((probe (claude-code-ide-mcp--trace-search pattern path))
               (cap (if (numberp cap) cap claude-code-ide-mcp--trace-block-cap))
               (root (claude-code-ide-mcp--trace-project-root
                      (claude-code-ide-mcp--grep-block-root path)))
               (store (claude-code-ide-mcp--trace-store-file root))
               (query-id (format-time-string "q%Y%m%dT%H%M%S%3N"))
               (known (claude-code-ide-mcp--trace-known store))
               (refreshed (claude-code-ide-mcp--trace-refresh root known))
               (collected (claude-code-ide-mcp--trace-collect
                           (car probe) root query-id
                           (claude-code-ide-mcp--flag-set-p local_scope)))
               (merged (claude-code-ide-mcp--trace-merge-unread
                        (plist-get collected :records) known))
               (records (if (> cap 0)
                            (seq-take merged cap)
                          merged))
               (resolved (claude-code-ide-mcp--trace-resolve
                          (append (plist-get refreshed :edges)
                                  (plist-get collected :edges))
                          root query-id))
               (file-records (claude-code-ide-mcp--trace-dedupe-files
                              (append (plist-get refreshed :files)
                                      (plist-get collected :files))
                              known))
               (counts (claude-code-ide-mcp--trace-classify
                        ;; Every producer goes through the merge, not just the
                        ;; ones that measure coverage: an endpoint record for
                        ;; a block already in the store must carry that
                        ;; block's `:unread' forward rather than erase it.
                        ;; Deduped first, so a block record wins the id.
                        (claude-code-ide-mcp--trace-merge-unread
                         (claude-code-ide-mcp--trace-dedupe-nodes
                          (append (plist-get refreshed :records)
                                  records
                                  (plist-get collected :endpoints)
                                  (plist-get resolved :nodes)))
                         known)
                        known
                        (claude-code-ide-mcp--trace-changed-imports
                         file-records known)))
               ;; Deduped before it is counted, because this number is the
               ;; caller's receipt for what reached the store.  Reporting the
               ;; raw derivations instead says 618 where 310 were written.
               (fresh-edges (claude-code-ide-mcp--trace-dedupe-edges
                             (seq-remove
                              (lambda (edge)
                                (gethash (claude-code-ide-mcp--trace-edge-key edge)
                                         (plist-get known :edges)))
                              (plist-get resolved :edges))))
               (query (list :k "query" :id query-id :tool "rg"
                            :pattern pattern
                            :path (or path "")
                            :ask (or ask "")
                            :n (length records)
                            :at (format-time-string "%FT%T%z"))))
          (when (cdr probe)
            ;; A search that could not run is not a search that found nothing,
            ;; so no absence is written for it.  What is written is a
            ;; retraction: an earlier run of this same pattern, before the exit
            ;; status was read, may have recorded its silence as a proof of
            ;; absence, and finding out that the pattern cannot be searched at
            ;; all is exactly the evidence that withdraws it.
            (when (seq-find (lambda (a)
                              (and (equal (plist-get a :claim) pattern)
                                   (null (plist-get a :by))))
                            (plist-get known :absent))
              (claude-code-ide-mcp--trace-append
               store
               (list (list :k "retracted" :claim pattern :q query-id
                           :reason (cdr probe)
                           :at (format-time-string "%FT%T%z")))))
            (error "Search did not run: %s" (cdr probe)))
          (claude-code-ide-mcp--trace-append
           store
           (append (list query)
                   file-records
                   (plist-get refreshed :gone)
                   (plist-get counts :new)
                   (plist-get counts :changed)
                   (plist-get counts :context)
                   (plist-get counts :moved)
                   fresh-edges
                   (unless (or records (plist-get resolved :edges))
                     ;; An absence carries what proved it.  Without that field
                     ;; there is no way to tell a search that ran and found
                     ;; nothing from one that never ran -- and a record written
                     ;; before this tool read ripgrep's exit status is exactly
                     ;; the second kind, so readers must be able to spot one.
                     (list (list :k "absent" :q query-id :claim pattern
                                 :by "rg exited 1: searched, matched nothing")))
                   (list (claude-code-ide-mcp--trace-scan-record root))))
          (claude-code-ide-mcp--trace-render
           records counts query store collected
           resolved fresh-edges refreshed)))
    (error (format "Error tracing: %s" (error-message-string err)))))

(claude-code-ide-make-tool
 :function #'claude-code-ide-mcp-trace
 :name "trace"
 :description "Search a seed pattern, grow every hit to its enclosing tree-sitter block, and record each block as a graph node in a per-project JSONL store. A node is identified by file, declaration path and, when it sits below a declaration, its position inside it -- never a line number -- and carries a hash of its text with comments and whitespace removed, so blocks sharing a hash are clones however they are named. Each clone group names the node kind, since a duplicated idiom is usually an inner block rather than a whole function. Comment-only blocks are refused. Every registration, ordering, attribute and signature the seed reaches becomes an edge, whose endpoints the language server resolves at the reference itself, and an endpoint it will not resolve stays a bare name rather than passing as a resolved one. Relations are read from the statement each match sits in, not from the whole block, so a one-line match does not have every name of its enclosing function recorded as something the seed reached; what the block holds outside those statements is listed as `unread' -- named, never followed, and offered as the next seed. Answers the clone query directly and reports how many nodes and edges were appended, so the caller can check the write instead of trusting it. Args: pattern (rg regex seed), path (search root, default project root), cap (max blocks, default 200, 0=unlimited), ask (the question this query answers, stored with it). Every file the seed matches is read -- scope a broad seed with path rather than expecting the tool to stop early. The report ends with what the run did not reach; read it before calling an answer complete."
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
Each comes back as (SIDE JOIN EDGE): SIDE is `in' or `out', JOIN is `id' when
the endpoint is this node's id and `name' when it is only this node's name.

An endpoint the server would not resolve is stored as a bare name, so an
edge into a node is written with the node's id at one end and a plain name at
the other.  Matching on the id alone answers nothing for the incoming
direction -- a store whose endpoints all stayed names answers nothing at all
-- while matching the name silently claims a resolution nobody made.  Both
are returned and the join is reported."
  (let ((alias (and (gethash id (plist-get known :nodes))
                    (claude-code-ide-mcp--graph-name-of id)))
        (out '()))
    (dolist (edge (plist-get known :edge-list))
      (when (or (null kinds) (member (plist-get edge :kind) kinds))
        (dolist (side '(out in))
          (when (memq direction (list side 'both))
            (let ((end (plist-get edge (if (eq side 'out) :from :to)))
                  (kind (plist-get edge (if (eq side 'out) :from_kind :to_kind))))
              (cond ((equal end id) (push (list side 'id edge) out))
                    ((and alias (equal kind "name") (equal end alias))
                     (push (list side 'name edge) out))))))))
    (nreverse out)))

(defun claude-code-ide-mcp--graph-locator (id known)
  "Return ID's file and line as one string, or an empty one when unknown."
  (let ((file (gethash id (plist-get known :node-files)))
        (line (gethash id (plist-get known :node-lines))))
    (if (and file line) (format "  %s:%d" file line) "")))

(defun claude-code-ide-mcp--graph-unread-line (id known)
  "Return what ID holds that no query has followed, read out of KNOWN.
Three answers, kept apart like the store's other silences: names still
outstanding, nothing outstanding, and nobody having looked.  A node recorded
only as the far end of an edge is the third."
  (let ((held (gethash id (plist-get known :node-unread))))
    (cond
     ((null (gethash id (plist-get known :nodes))) "")
     ((null held)
      "  unread: unmeasured -- this node was recorded without reading what it holds\n")
     ((zerop (length held))
      "  unread: none -- every call and type in this node has been followed\n")
     (t
      (let ((names (append held nil)))
        (format "  unread: %d never followed -- %s%s\n"
                (length names)
                (string-join
                 (seq-take names claude-code-ide-mcp--trace-unread-names-shown)
                 " ")
                (if (> (length names)
                       claude-code-ide-mcp--trace-unread-names-shown)
                    (format " +%d"
                            (- (length names)
                               claude-code-ide-mcp--trace-unread-names-shown))
                  "")))))))

(defun claude-code-ide-mcp--graph-edge-line (side join edge known level)
  "Render EDGE seen from SIDE at LEVEL, reading locators out of KNOWN.
JOIN is how the edge was reached: `id' or `name', and a name join is said so,
since it rests on the two ends sharing a name rather than on a resolution."
  (let* ((other (if (eq side 'in) (plist-get edge :from) (plist-get edge :to)))
         (kind (if (eq side 'in)
                   (plist-get edge :from_kind)
                 (plist-get edge :to_kind)))
         (mark (cond ((equal kind "node") "")
                     ((equal kind "external") "  (external)")
                     (t "  (unresolved name)"))))
    (format "%s%s %-10s %s%s%s%s   [%s %s]"
            (make-string (* 2 level) ?\s)
            (if (eq side 'in) "<-" "->")
            (plist-get edge :kind)
            other
            (if (equal kind "node")
                (claude-code-ide-mcp--graph-locator other known)
              "")
            mark
            (if (eq join 'name) "  (matched by name)" "")
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
             (dolist (cell (claude-code-ide-mcp--graph-touching
                            node kinds direction known))
               (let* ((side (nth 0 cell))
                      (join (nth 1 cell))
                      (edge (nth 2 cell))
                      (other (if (eq side 'in)
                                 (plist-get edge :from)
                               (plist-get edge :to))))
                 (puthash (plist-get edge :q) t used)
                 (push (claude-code-ide-mcp--graph-edge-line
                        side join edge known level)
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
     (let ((unproven (seq-count (lambda (a) (null (plist-get a :by)))
                                (plist-get known :absent))))
       (if (zerop unproven)
           ""
         (format "unproven: %d of the absences here were written before this tool read ripgrep's exit status, so they may record a search that never ran rather than one that found nothing -- re-run their query to settle it\n"
                 unproven)))
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
                 (claude-code-ide-mcp--graph-unread-line id known)
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
 :description "Read the graph `trace' recorded, with no language-server round trip and without opening any code. Give it a node id or a bare name to see what registers, orders, requires or takes that thing, and what it takes in turn; leave the name out to see what the store already holds, which is the cheap way to find out whether a question has been answered before. Every edge line carries its evidence kind and the id of the query that produced it, and those queries are printed underneath so a reviewer can re-run them instead of trusting the answer. Emptiness is reported three ways -- never traced, traced with no such edge, or a name matching several nodes -- because those are different facts. A node also says what it holds that nobody has followed, again in three states: names still outstanding, nothing outstanding, or never measured, so the edges it does carry cannot read as everything it has. Args: from (node id or name; omit for a summary), kinds (comma-separated edge kinds), depth (hops, default 1), direction (in | out | both), path (project, default the current one)."
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
