;;; +describe-symbol.el --- MCP tool: describe Emacs symbol -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(defun claude-code-ide-mcp--function-source (sym)
  "Return source code string for SYM, or nil if unavailable."
  (ignore-errors
    (let* ((loc (find-function-noselect sym t))
           (buf (car loc))
           (pos (cdr loc)))
      (when (and buf pos)
        (with-current-buffer buf
          (save-excursion
            (goto-char pos)
            (let ((start (point)))
              (forward-sexp 1)
              (buffer-substring-no-properties start (point)))))))))

(defun claude-code-ide-mcp--describe-function-part (sym name)
  "Return function documentation string for SYM (named NAME)."
  (let* ((fn (symbol-function sym))
         (real-fn (if (autoloadp fn) (ignore-errors (autoload-do-load fn sym) (symbol-function sym)) fn))
         (native-p (and (fboundp 'subr-native-elisp-p)
                        (ignore-errors (subr-native-elisp-p real-fn))))
         (doc (documentation sym t))
         (args (help-function-arglist sym t))
         (type (cond ((and (subrp real-fn) (not native-p)) "built-in")
                     ((macrop sym) "macro")
                     (t "function")))
         (interactive-p (commandp sym))
         (autoloaded-p (ignore-errors
                         (seq-some #'stringp (get sym 'function-history))))
         (qualifiers (delq nil (list (when autoloaded-p "autoloaded")
                                    (when native-p "natively compiled"))))
         (file (ignore-errors (find-lisp-object-file-name sym 'defun)))
         (keys (where-is-internal sym nil t))
         (source (claude-code-ide-mcp--function-source sym)))
    (concat
     (format "%s is %s%s"
             name
             (if qualifiers
                 (concat "an " (mapconcat #'identity qualifiers ", ") " ")
               "a ")
             type)
     (if interactive-p " (interactive command)" "")
     ".\n"
     (when file (format "Defined in: %s\n" file))
     (format "\nSignature:\n(%s%s)\n"
             name
             (if args (format " %s" args) ""))
     (when keys
       (format "\nKey bindings: %s\n"
               (mapconcat #'key-description (where-is-internal sym) ", ")))
     (format "\nDocumentation:\n%s\n" (or doc "No documentation available."))
     (when source
       (format "\nSource:\n%s\n" source)))))

(defun claude-code-ide-mcp--variable-source (sym)
  "Return source code string for variable SYM, or nil if unavailable."
  (ignore-errors
    (let* ((loc (find-variable-noselect sym))
           (buf (car loc))
           (pos (cdr loc)))
      (when (and buf pos)
        (with-current-buffer buf
          (save-excursion
            (goto-char pos)
            (let ((start (point)))
              (forward-sexp 1)
              (buffer-substring-no-properties start (point)))))))))

(defun claude-code-ide-mcp--describe-variable-part (sym name)
  "Return variable documentation string for SYM (named NAME)."
  (let* ((doc (documentation-property sym 'variable-documentation t))
         (val (symbol-value sym))
         (val-str (let ((s (format "%S" val)))
                    (if (> (length s) 300)
                        (concat (substring s 0 300) " ...")
                      s)))
         (local-p (local-variable-p sym))
         (custom-p (custom-variable-p sym))
         (custom-type (get sym 'custom-type))
         (standard-val (ignore-errors
                         (car (get sym 'standard-value))))
         (standard-str (when standard-val
                         (let ((s (format "%S" (eval standard-val))))
                           (if (> (length s) 200)
                               (concat (substring s 0 200) " ...")
                             s))))
         (file (ignore-errors
                 (find-lisp-object-file-name sym 'defvar)))
         (source (claude-code-ide-mcp--variable-source sym)))
    (concat
     (format "%s is a%s variable"
             name
             (if custom-p " customizable" ""))
     (when file (format " defined in\n%s" file))
     ".\n"
     (format "\nValue:\n%s\n" val-str)
     (when (and standard-str (not (equal val-str standard-str)))
       (format "\nDefault value:\n%s\n" standard-str))
     (when custom-type
       (format "\nCustom type: %S\n" custom-type))
     (format "\nBuffer-local: %s\n" (if local-p "yes" "no"))
     (format "\nDocumentation:\n%s\n" (or doc "No documentation available."))
     (when source
       (format "\nSource:\n%s\n" source)))))

(defun claude-code-ide-mcp-describe-symbol (name)
  "Get full documentation for Emacs symbol NAME as function, variable, or both."
  (condition-case err
      (let ((sym (intern-soft name)))
        (cond
         ((not sym)
          (format "Symbol '%s' not found." name))
         (t
          (let ((parts (delq nil
                             (list (when (fboundp sym)
                                     (claude-code-ide-mcp--describe-function-part sym name))
                                   (when (boundp sym)
                                     (claude-code-ide-mcp--describe-variable-part sym name))))))
            (if parts
                (mapconcat #'identity parts "\n\n---\n\n")
              (format "'%s' is not a function or variable." name))))))
    (error
     (format "Error describing symbol '%s': %s" name (error-message-string err)))))

(claude-code-ide-make-tool
    :function #'claude-code-ide-mcp-describe-symbol
    :name "claude-code-ide-mcp-describe-symbol"
    :description "Get full documentation for any Emacs symbol. If the symbol is a function/command, returns docstring, argument list, type (built-in/macro/command/function), source file, key bindings, autoload/native-compile status, and source code. If it is a variable, returns docstring, current value, default value, custom type, buffer-local status, source file, and source code. Shows both if the symbol is both a function and a variable."
    :args '((
        :name "name"
        :type string
        :description "The name of the Emacs symbol to describe")))

(provide '+describe-symbol)
;;; +describe-symbol.el ends here
