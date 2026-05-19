;;; +find-references.el --- MCP tool: find all references to an Elisp symbol -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

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
          (let* ((loaded-src-bufs (mapcar #'elisp-refs--contents-buffer
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
    :name "claude-code-ide-mcp-elisp-find-references"
    :description "Find all call-sites for an Elisp function across all loaded files. Returns file paths and the surrounding lines for each reference. Equivalent to helpful's 'Find all references' button. Only works with Elisp symbols."
    :args '((:name "name"
             :type string
             :description "The name of the Elisp function to find references for")))

(provide '+find-references)
;;; +find-references.el ends here
