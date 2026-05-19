;;; +buffer-info.el --- MCP tool: buffer name and major mode -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(defun claude-code-ide-mcp-buffer-info (&optional buffer-name)
  "Return name and major-mode for buffers.
If BUFFER-NAME is given, return info for that buffer only.
Otherwise return all user-visible buffers ordered by recency."
  (condition-case err
      (if (and buffer-name (not (string-empty-p buffer-name)))
          (let ((buf (get-buffer buffer-name)))
            (if buf
                (with-current-buffer buf
                  (format "buffer: %s\nmajor-mode: %s" (buffer-name) (symbol-name major-mode)))
              (format "Buffer '%s' not found." buffer-name)))
        (let ((bufs (seq-filter
                     (lambda (b)
                       (not (string-prefix-p " " (buffer-name b))))
                     (buffer-list))))
          (mapconcat
           (lambda (b)
             (with-current-buffer b
               (format "%s  [%s]" (buffer-name) (symbol-name major-mode))))
           bufs
           "\n")))
    (error (format "Error: %s" (error-message-string err)))))

(claude-code-ide-make-tool
    :function #'claude-code-ide-mcp-buffer-info
    :name "claude-code-ide-mcp-buffer-info"
    :description "Return buffer name and major-mode. With no argument, lists all user-visible buffers ordered by recency (most recently used first). Pass a buffer name to get info for that specific buffer only."
    :args '((:name "buffer_name"
             :type string
             :description "Optional buffer name. Omit to list all user-visible buffers.")))

(defun claude-code-ide-mcp-last-user-buffer ()
  "Return the most recently used buffer that is not internal or a claude-code buffer."
  (condition-case err
      (let ((buf (seq-find
                  (lambda (b)
                    (let ((name (buffer-name b)))
                      (and (not (string-prefix-p " " name))
                           (not (string-match-p "\\*claude-code" name)))))
                  (buffer-list))))
        (if buf
            (with-current-buffer buf
              (format "buffer: %s\nmajor-mode: %s" (buffer-name) (symbol-name major-mode)))
          "No user buffer found."))
    (error (format "Error: %s" (error-message-string err)))))

(claude-code-ide-make-tool
    :function #'claude-code-ide-mcp-last-user-buffer
    :name "claude-code-ide-mcp-last-user-buffer"
    :description "Return the most recently used buffer that is not an internal buffer or a claude-code buffer. Useful for identifying which file the user was last editing."
    :args '())

(provide '+buffer-info)
;;; +buffer-info.el ends here
