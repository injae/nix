;;; +ai.el --- Summery -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(defun claude-code-ide-mcp-describe-function (name)
  "Get documentation and signature for Emacs function NAME."
  (condition-case err
      (let ((sym (intern-soft name)))
        (cond
         ((not sym)
          (format "Symbol '%s' not found." name))
         ((not (fboundp sym))
          (format "'%s' is not a function." name))
         (t
          (let* ((doc (documentation sym t))
                 (args (help-function-arglist sym t))
                 (fn (symbol-function sym))
                 (type (cond ((subrp fn) "built-in function")
                             ((macrop sym) "macro")
                             ((commandp sym) "command")
                             (t "function")))
                 (file (ignore-errors
                         (find-lisp-object-file-name sym 'defun))))
            (concat
             (format "%s is a %s.\n" name type)
             (when file (format "Defined in: %s\n" file))
             (format "Arguments: %s\n\n"
                     (if args (format "(%s %s)" name args) (format "(%s)" name)))
             (or doc "No documentation available."))))))
    (error
     (format "Error describing function '%s': %s" name (error-message-string err)))))

(defun claude-code-ide-mcp-describe-variable (name)
  "Get documentation and current value for Emacs variable NAME."
  (condition-case err
      (let ((sym (intern-soft name)))
        (cond
         ((not sym)
          (format "Symbol '%s' not found." name))
         ((not (boundp sym))
          (format "'%s' is not a variable." name))
         (t
          (let* ((doc (documentation-property sym 'variable-documentation t))
                 (val (symbol-value sym))
                 (val-str (let ((s (format "%S" val)))
                            (if (> (length s) 300)
                                (concat (substring s 0 300) " ...")
                              s)))
                 (local-p (local-variable-p sym))
                 (custom-p (custom-variable-p sym))
                 (file (ignore-errors
                         (find-lisp-object-file-name sym 'defvar))))
            (concat
             (format "%s is a variable.\n" name)
             (when file (format "Defined in: %s\n" file))
             (format "Value: %s\n" val-str)
             (format "Buffer-local: %s\n" (if local-p "yes" "no"))
             (format "Customizable: %s\n\n" (if custom-p "yes" "no"))
             (or doc "No documentation available."))))))
    (error
     (format "Error describing variable '%s': %s" name (error-message-string err)))))

(use-package claude-code-ide :ensure (:repo "manzaltu/claude-code-ide.el" :host github)
    :general (leader "a" '(claude-code-ide-menu :wk "Claude Code IDE Menu"))
    :custom
    (claude-code-ide-open-in-new-frame t)
    (claude-code-ide-enable-mcp-server t)
    (claude-code-ide-terminal-backend 'vterm)
    (claude-code-ide-vterm-anti-flicker t)
    (claude-code-ide-vterm-render-delay 0.01)
    :config
    (claude-code-ide-emacs-tools-setup)
    (claude-code-ide-make-tool
        :function #'claude-code-ide-mcp-describe-function
        :name "claude-code-ide-mcp-describe-function"
        :description "Get full documentation and signature for any Emacs function or command. Returns the docstring, argument list, type (built-in/macro/command/function), and source file."
        :args '((
            :name "name"
            :type string
            :description "The name of the Emacs function or command to describe")))
    (claude-code-ide-make-tool
        :function #'claude-code-ide-mcp-describe-variable
        :name "claude-code-ide-mcp-describe-variable"
        :description "Get full documentation and current value for any Emacs variable. Returns the docstring, current value, whether it is buffer-local or customizable, and source file."
        :args '((
            :name "name"
            :type string
            :description "The name of the Emacs variable to describe")))
)

(provide '+ai)
;;; +ai.el ends here
