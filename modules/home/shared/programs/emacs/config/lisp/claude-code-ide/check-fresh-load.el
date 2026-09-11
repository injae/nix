;;; check-fresh-load.el --- name every function this package calls but lacks -*- lexical-binding: t; -*-

;;; Commentary:

;; A running Emacs keeps functions the file no longer defines, so deleting one
;; while its callers remain passes every runtime test and breaks on the next
;; start.  That happened: a refactor removed three helpers, four call sites
;; stayed, and the tools kept working all session because the old definitions
;; were still in the image.
;;
;; Run this against a fresh image, which knows nothing:
;;
;;     emacs -Q --batch -l check-fresh-load.el <this directory>
;;
;; It loads the file and asks, of every `claude-code-ide-mcp-' name it calls,
;; whether that name exists.  Exits non-zero and lists what does not.

;;; Code:

(require 'cl-lib)

(defconst check-fresh-load-file "extras/claude-code-ide-extra-trace.el"
  "The package file to load and then check for gaps.")

(let* ((dir (or (car command-line-args-left) default-directory))
       (file (expand-file-name check-fresh-load-file dir)))
  (add-to-list 'load-path dir)
  (add-to-list 'load-path (expand-file-name "extras" dir))
  (condition-case err
      (load file nil t)
    (error (princ (format "LOAD FAILED: %s\n" (error-message-string err)))
           (kill-emacs 1)))
  (let ((missing '()))
    (with-temp-buffer
      (insert-file-contents file)
      (goto-char (point-min))
      (while (re-search-forward "(\\(claude-code-ide-mcp-[a-z0-9-]+\\)" nil t)
        (let ((name (intern (match-string 1))))
          ;; `boundp' too: a variable bound in a `let' reads like a call here.
          (unless (or (fboundp name) (macrop name) (boundp name)
                      (memq name missing))
            (push name missing)))))
    (if missing
        (progn (princ (format "UNDEFINED: %s\n" missing))
               (kill-emacs 1))
      (princ "fresh load clean\n"))))

;;; check-fresh-load.el ends here
