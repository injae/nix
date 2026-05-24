;;; claude-code-ide-extra-navigation.el --- MCP tools: file and line navigation -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(require 'claude-code-ide-mcp-server)

(defun claude-code-ide-mcp-goto-file-line (file-path line)
  "Open FILE-PATH at LINE in the primary code window (non-claude, non-magit)."
  (condition-case err
      (let* ((code-window
              (or (seq-find
                   (lambda (w)
                     (let ((name (buffer-name (window-buffer w))))
                       (and (not (string-match-p "\\*claude-code" name))
                            (not (string-match-p "^magit" name))
                            (not (string-prefix-p " " name))
                            (not (string-match-p "^\\*" name)))))
                   (window-list))
                  (seq-find
                   (lambda (w)
                     (not (string-match-p "\\*claude-code"
                                          (buffer-name (window-buffer w)))))
                   (window-list))
                  (selected-window))))
        (with-selected-window code-window
          (find-file file-path)
          (goto-char (point-min))
          (forward-line (1- line))
          (recenter 5)
          (format "Opened %s at line %d" file-path line)))
    (error (format "Error: %s" (error-message-string err)))))

(claude-code-ide-make-tool
    :function #'claude-code-ide-mcp-goto-file-line
    :name "goto_line"
    :description "Open a source file at a specific line in the primary code window (non-claude, non-magit). Scrolls so the target line is near the top. Use this before explaining an issue to focus the user's view."
    :args '((:name "file_path"
             :type string
             :description "Absolute path to the file to open")
            (:name "line"
             :type number
             :description "Line number to navigate to (1-based)")))

(provide 'claude-code-ide-extra-navigation)
;;; claude-code-ide-extra-navigation.el ends here
