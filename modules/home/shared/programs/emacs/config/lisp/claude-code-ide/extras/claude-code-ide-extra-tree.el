;;; claude-code-ide-extra-tree.el --- MCP tools: repository structure tree -*- lexical-binding: t; -*-
;;; Commentary:
;; structure-tree: depth-limited directory tree of a repository, optionally
;; carrying each file's top-level declarations.  Directories past the depth
;; limit are summarized rather than dropped.
;;; Code:

(require 'imenu)
(require 'claude-code-ide-mcp-server)
(require 'claude-code-ide-extra-buffer-info)
(require 'claude-code-ide-extra-search)

(defconst claude-code-ide-mcp--tree-symbol-size-limit 1000000
  "Files larger than this are listed without symbols.")

(defun claude-code-ide-mcp--tree-git-files (root)
  "Return paths under ROOT from git, or nil when ROOT is not in a repository.
Untracked files are included, ignored ones are not."
  (let ((default-directory root))
    (with-temp-buffer
      (when (eq 0 (process-file "git" nil t nil
                                "ls-files" "--cached" "--others" "--exclude-standard"))
        (split-string (buffer-string) "\n" t)))))

(defun claude-code-ide-mcp--tree-disk-files (root)
  "Return paths under ROOT from the filesystem, skipping dot directories."
  (mapcar (lambda (file) (file-relative-name file root))
          (directory-files-recursively
           root "" nil
           (lambda (dir) (not (string-prefix-p "." (file-name-nondirectory dir)))))))

(defun claude-code-ide-mcp--tree-build (paths)
  "Return a nested hash tree from relative PATHS.
A directory node holds a hash table; a file node holds nil."
  (let ((root (make-hash-table :test 'equal)))
    (dolist (path paths)
      (let ((node root)
            (segments (split-string path "/" t)))
        (while (cdr segments)
          (let ((child (gethash (car segments) node)))
            (unless (hash-table-p child)
              (setq child (make-hash-table :test 'equal))
              (puthash (car segments) child node))
            (setq node child))
          (setq segments (cdr segments)))
        (unless (gethash (car segments) node)
          (puthash (car segments) nil node))))
    root))

(defun claude-code-ide-mcp--tree-count (node)
  "Return (FILES . DIRS) contained in NODE, recursively."
  (let ((files 0)
        (dirs 0))
    (maphash (lambda (_name value)
               (if (hash-table-p value)
                   (let ((sub (claude-code-ide-mcp--tree-count value)))
                     (setq dirs (+ dirs 1 (cdr sub))
                           files (+ files (car sub))))
                 (setq files (1+ files))))
             node)
    (cons files dirs)))

(defun claude-code-ide-mcp--tree-node-names (node)
  "Return (DIRS . FILES), each a sorted name list of NODE."
  (let (dirs files)
    (maphash (lambda (name value)
               (if (hash-table-p value) (push name dirs) (push name files)))
             node)
    (cons (sort dirs #'string<) (sort files #'string<))))

(defun claude-code-ide-mcp--tree-symbols (file)
  "Return top-level symbol lines for FILE, or nil when it has none."
  (when (< (or (file-attribute-size (file-attributes file)) 0)
           claude-code-ide-mcp--tree-symbol-size-limit)
    (let ((inhibit-redisplay t))
      (with-current-buffer (or (claude-code-ide-mcp--refresh-visiting file)
                               (find-file-noselect file))
        (save-excursion
          ;; Same reason as `claude-code-ide-mcp-file-outline': a cached index
          ;; hands back stale marker positions.
          (setq imenu--index-alist nil)
          (let* ((index (condition-case _ (imenu--make-index-alist t) (error nil)))
                 (pairs (when index (claude-code-ide-mcp--imenu-collect index ""))))
            (mapcar #'cdr (sort pairs (lambda (a b) (< (car a) (car b)))))))))))

(defun claude-code-ide-mcp--tree-render (node rel indent depth root symbols cap counters)
  "Return rendered lines for NODE, the directory at relative path REL.
INDENT prefixes every line.  DEPTH is how many more directory levels may be
entered; at 0 a directory is summarized instead.  ROOT anchors REL.  When
SYMBOLS is non-nil each file is expanded until CAP files carry symbols (0 =
unlimited).  COUNTERS holds the expanded-file count, mutated as we descend."
  (let ((split (claude-code-ide-mcp--tree-node-names node))
        (lines '()))
    (dolist (dir (car split))
      (let ((child (gethash dir node)))
        (if (<= depth 0)
            (let ((counts (claude-code-ide-mcp--tree-count child)))
              (setq lines (append lines
                                  (list (format "%s%s/  … (%d files, %d dirs)"
                                                indent dir
                                                (car counts) (cdr counts))))))
          (setq lines
                (append lines
                        (list (format "%s%s/" indent dir))
                        (claude-code-ide-mcp--tree-render
                         child
                         (if (string-empty-p rel) dir (concat rel "/" dir))
                         (concat indent "  ") (1- depth) root symbols cap counters))))))
    (dolist (file (cdr split))
      (setq lines (append lines (list (concat indent file))))
      (when (and symbols (or (<= cap 0) (< (car counters) cap)))
        (let ((found (claude-code-ide-mcp--tree-symbols
                      (expand-file-name
                       (if (string-empty-p rel) file (concat rel "/" file))
                       root))))
          (when found
            (setcar counters (1+ (car counters)))
            (setq lines (append lines
                                (mapcar (lambda (line) (concat indent "  " line))
                                        found)))))))
    lines))

(defun claude-code-ide-mcp-structure-tree (&optional path depth symbols pattern cap)
  "Return a depth-limited structure tree of the repository at PATH.
PATH defaults to the project root.  DEPTH limits how many directory levels
are entered (default 3; 0 = unlimited); deeper directories are summarized
with their file and directory counts rather than dropped.  SYMBOLS adds each
file's top-level declarations with line numbers.  PATTERN keeps only paths
matching that regexp.  CAP limits how many files get symbols (default 40;
0 = unlimited)."
  (condition-case err
      (let* ((root (claude-code-ide-mcp--grep-block-root path))
             (root (file-name-as-directory root))
             (depth (cond ((not (numberp depth)) 3)
                          ((<= depth 0) most-positive-fixnum)
                          (t depth)))
             (cap (if (numberp cap) cap 40))
             (paths (or (claude-code-ide-mcp--tree-git-files root)
                        (claude-code-ide-mcp--tree-disk-files root)))
             (paths (if (and pattern (not (string-empty-p pattern)))
                        (seq-filter (lambda (p) (string-match-p pattern p)) paths)
                      paths)))
        (if (null paths)
            (format "No files under %s." root)
          (let* ((counters (list 0))
                 (lines (claude-code-ide-mcp--tree-render
                         (claude-code-ide-mcp--tree-build paths)
                         "" "" depth root symbols cap counters)))
            (concat
             (format "root: %s\n%d files%s\n\n"
                     root (length paths)
                     (if symbols
                         (format ", symbols for %d" (car counters))
                       ""))
             (string-join lines "\n")))))
    (error (format "Error: %s" (error-message-string err)))))

(claude-code-ide-make-tool
    :function #'claude-code-ide-mcp-structure-tree
    :name "structure-tree"
    :description "Depth-limited structure tree of a repository. Directories past the depth limit are summarized with their file/dir counts, never silently dropped. Honors .gitignore. Args: path (optional root, default project), depth (optional max directory levels, default 3, 0=unlimited), symbols (optional; add each file's top-level declarations with line numbers), pattern (optional regexp on the relative path), cap (optional max files expanded with symbols, default 40, 0=unlimited). Survey with a small depth, then re-run deeper on one path."
    :args '((:name "path"
             :type string
             :description "Tree root dir (optional; default project root)")
            (:name "depth"
             :type number
             :description "Max directory levels to enter (optional; default 3, 0=unlimited)")
            (:name "symbols"
             :type boolean
             :description "Add each file's top-level declarations with line numbers (optional)")
            (:name "pattern"
             :type string
             :description "Keep only relative paths matching this regexp (optional)")
            (:name "cap"
             :type number
             :description "Max files expanded with symbols (optional; default 40, 0=unlimited)")))

(provide 'claude-code-ide-extra-tree)
;;; claude-code-ide-extra-tree.el ends here
