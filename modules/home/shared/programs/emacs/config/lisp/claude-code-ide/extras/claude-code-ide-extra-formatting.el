;;; claude-code-ide-extra-formatting.el --- MCP tools: apheleia formatter -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(require 'claude-code-ide-mcp-server)

(defun claude-code-ide-mcp--apheleia-with-buffer (file-path fn)
    "Visit FILE-PATH buffer and call FN with it current."
    (let ((inhibit-redisplay t)
             (buf (or (find-buffer-visiting file-path)
                      (find-file-noselect file-path))))
        (with-current-buffer buf
            (funcall fn))))

(defun claude-code-ide-mcp--apheleia-get-formatters ()
    "Return formatter list for current buffer."
    (cond
        ((fboundp 'apheleia--get-formatters)
            (apheleia--get-formatters 'interactive))
        (t
            (let ((entry (alist-get major-mode apheleia-mode-alist)))
                (cond ((null entry) nil)
                    ((symbolp entry) (list entry))
                    ((listp entry) entry)
                    (t nil))))))

(defun claude-code-ide-mcp-formatter-info (file-path)
    "Return formatter configuration for FILE-PATH."
    (condition-case err
        (claude-code-ide-mcp--apheleia-with-buffer file-path
            (lambda ()
                (let ((formatters (claude-code-ide-mcp--apheleia-get-formatters)))
                    (if (null formatters)
                        (format "No formatter configured for mode: %s" (symbol-name major-mode))
                        (format "file: %s\nmode: %s\nformatters: %s\n\nCommands:\n%s"
                            (buffer-file-name)
                            (symbol-name major-mode)
                            (mapconcat #'symbol-name formatters ", ")
                            (mapconcat
                                (lambda (fmt)
                                    (let ((cmd (alist-get fmt apheleia-formatters)))
                                        (format "  %s: %s" fmt
                                            (if cmd (format "%S" cmd) "(not found)"))))
                                formatters "\n"))))))
        (error (format "Error: %s" (error-message-string err)))))

(defun claude-code-ide-mcp-list-formatters ()
    "List all mode-to-formatter mappings in apheleia-mode-alist."
    (condition-case err
        (format "Mode-formatter mappings (%d):\n\n%s"
            (length apheleia-mode-alist)
            (mapconcat
                (lambda (entry)
                    (let ((mode (car entry))
                             (fmts (cdr entry)))
                        (format "  %-30s %s"
                            (cond ((symbolp mode) (symbol-name mode))
                                ((stringp mode) mode)
                                (t (format "%S" mode)))
                            (cond ((symbolp fmts) (symbol-name fmts))
                                ((listp fmts) (mapconcat #'symbol-name fmts " "))
                                (t (format "%S" fmts))))))
                apheleia-mode-alist "\n"))
        (error (format "Error: %s" (error-message-string err)))))

(defun claude-code-ide-mcp-format-buffer (file-path)
    "Run apheleia formatter on FILE-PATH."
    (condition-case err
        (claude-code-ide-mcp--apheleia-with-buffer file-path
            (lambda ()
                (let ((formatters (claude-code-ide-mcp--apheleia-get-formatters)))
                    (if (null formatters)
                        (format "No formatter configured for mode: %s in %s"
                            (symbol-name major-mode) file-path)
                        (apheleia-format-buffer formatters nil)
                        (format "Triggered formatting of %s\nFormatters: %s"
                            (buffer-name)
                            (mapconcat #'symbol-name formatters ", "))))))
        (error (format "Error: %s" (error-message-string err)))))

(claude-code-ide-make-tool
    :function #'claude-code-ide-mcp-formatter-info
    :name "formatter_info"
    :description "Get formatter configuration for a file: shows the major mode, which formatters are active, and their command definitions."
    :args '((:name "file_path"
                :type string
                :description "Absolute path to the file to inspect")))

(claude-code-ide-make-tool
    :function #'claude-code-ide-mcp-list-formatters
    :name "list_formatters"
    :description "List all mode-to-formatter mappings configured in apheleia-mode-alist. Shows every mode and which formatter(s) are assigned to it."
    :args '())

(claude-code-ide-make-tool
    :function #'claude-code-ide-mcp-format-buffer
    :name "format_buffer"
    :description "Run the apheleia formatter on a specific file. Opens the file if not already open and triggers formatting asynchronously."
    :args '((:name "file_path"
                :type string
                :description "Absolute path to the file to format")))

(provide 'claude-code-ide-extra-formatting)
;;; claude-code-ide-extra-formatting.el ends here
