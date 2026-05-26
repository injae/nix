;;; claude-code-ide-extra-elisp.el --- MCP tools: Emacs Lisp analysis -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(require 'claude-code-ide-mcp-server)

(defun claude-code-ide-mcp-elisp-callees (name)
  "Return all functions called by the Elisp function NAME.
Uses macro-expansion so indirect calls via macros are included."
  (condition-case err
      (let ((sym (intern-soft name))
            (_ (require 'helpful nil 'noerror)))
        (cond
         ((not sym)
          (format "Symbol '%s' not found." name))
         ((not (fboundp sym))
          (format "'%s' is not a function." name))
         (t
          (let* ((location (find-function-noselect sym t))
                 (buf (car location))
                 (pos (cdr location)))
            (if (not (and buf pos))
                (format "Cannot find source for '%s' (built-in or interactively defined)." name)
              (let* ((form
                      (with-current-buffer buf
                        (let ((inhibit-redisplay t))
                          (save-excursion
                            (goto-char pos)
                            (read (current-buffer))))))
                     (callees (helpful--callees form)))
                (if (null callees)
                    (format "'%s' does not call any other named functions." name)
                  (format "Functions called by '%s' (%d):\n%s"
                          name
                          (length callees)
                          (mapconcat #'symbol-name callees "\n")))))))))
    (error (format "Error finding callees for '%s': %s"
                   name (error-message-string err)))))

(claude-code-ide-make-tool
    :function #'claude-code-ide-mcp-elisp-callees
    :name "elisp-callees"
    :description "Fns called by Elisp fn. Macro-expanded; includes indirect calls. Only Elisp symbols."
    :args '((:name "name"
             :type string
             :description "Elisp function name")))


(defun claude-code-ide-mcp-elisp-load-file (file-path)
  "Load FILE-PATH into the running Emacs session."
  (condition-case err
      (progn
        (load-file file-path)
        (format "Loaded: %s" file-path))
    (error (format "Error: %s" (error-message-string err)))))

(claude-code-ide-make-tool
    :function #'claude-code-ide-mcp-elisp-load-file
    :name "elisp-load"
    :description "Load .el file via load-file. Test edits interactively."
    :args '((:name "file_path"
             :type string
             :description "Absolute path to .el file")))

(defun claude-code-ide-mcp--elisp-refs-extract (raw-results)
  "Extract file paths and line text from RAW-RESULTS while source buffers are alive."
  (mapcar
   (lambda (item)
     (let* ((forms-list (car item))
            (buf (cdr item))
            (path (buffer-local-value 'elisp-refs--path buf))
            (lines (mapcar
                    (lambda (form-item)
                      (substring-no-properties
                       (elisp-refs--containing-lines buf (nth 1 form-item) (nth 2 form-item))))
                    forms-list)))
       (cons path lines)))
   raw-results))

(defun claude-code-ide-mcp-elisp-find-references (name)
  "Find all call-sites for Elisp function NAME across all loaded files."
  (condition-case err
      (let ((sym (intern-soft name)))
        (cond
         ((not sym)
          (format "Symbol '%s' not found." name))
         ((not (fboundp sym))
          (format "'%s' is not a function." name))
         (t
          (let* ((_ (require 'elisp-refs nil 'noerror))
                 (loaded-src-bufs (mapcar #'elisp-refs--contents-buffer
                                           (elisp-refs--loaded-paths)))
                 (extracted
                  (unwind-protect
                      (claude-code-ide-mcp--elisp-refs-extract
                       (elisp-refs--search-1
                        loaded-src-bufs
                        (lambda (buf)
                          (elisp-refs--read-and-find buf sym #'elisp-refs--function-p))))
                    (dolist (buf loaded-src-bufs)
                      (when (buffer-live-p buf)
                        (kill-buffer buf))))))
            (if (null extracted)
                (format "No references found for '%s'." name)
              (format "References to '%s' (%d file(s)):\n\n%s"
                      name
                      (length extracted)
                      (mapconcat
                       (lambda (item)
                         (format "File: %s\n%s"
                                 (car item)
                                 (mapconcat #'identity (cdr item) "\n")))
                       extracted
                       "\n\n")))))))
    (error (format "Error finding references for '%s': %s"
                   name (error-message-string err)))))

(claude-code-ide-make-tool
    :function #'claude-code-ide-mcp-elisp-find-references
    :name "elisp-refs"
    :description "All call-sites for Elisp fn across loaded files. file:line + context. Only Elisp symbols."
    :args '((:name "name"
             :type string
             :description "Elisp function name")))

(provide 'claude-code-ide-extra-elisp)
;;; claude-code-ide-extra-elisp.el ends here
