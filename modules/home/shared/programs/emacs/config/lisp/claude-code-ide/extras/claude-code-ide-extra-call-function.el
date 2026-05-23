;;; claude-code-ide-extra-call-function.el --- MCP tool: call any Emacs function by name -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(require 'claude-code-ide-mcp-server)

(defun claude-code-ide-mcp--json-to-elisp (val)
  "Convert a value returned by `json-parse-string' to an Elisp argument.
JSON null → nil, JSON true/false → t/nil, arrays → lists, objects → alists."
  (cond
   ((eq val :null) nil)
   ((eq val :false) nil)
   ((eq val :true) t)
   ((vectorp val) (mapcar #'claude-code-ide-mcp--json-to-elisp (seq-into val 'list)))
   ((hash-table-p val)
    (let (result)
      (maphash (lambda (k v)
                 (push (cons (intern k) (claude-code-ide-mcp--json-to-elisp v)) result))
               val)
      (nreverse result)))
   (t val)))

(defun claude-code-ide-mcp-call-function (name args-json)
  "Call Emacs function NAME with arguments decoded from ARGS-JSON.
ARGS-JSON must be a JSON array string whose elements become the positional
arguments to NAME.  Pass \"[]\" or \"\" for zero-argument calls."
  (condition-case err
      (let ((sym (intern-soft name)))
        (cond
         ((not sym)
          (format "Symbol '%s' not found." name))
         ((not (fboundp sym))
          (format "'%s' is not a function." name))
         (t
          (let* ((args
                  (if (or (null args-json) (string-empty-p (string-trim args-json)))
                      nil
                    (mapcar #'claude-code-ide-mcp--json-to-elisp
                            (seq-into
                             (json-parse-string args-json
                                               :null-object :null
                                               :false-object :false)
                             'list))))
                 (result (apply sym args)))
            (prin1-to-string result)))))
    (error (format "Error calling '%s': %s" name (error-message-string err)))))

(claude-code-ide-make-tool
    :function #'claude-code-ide-mcp-call-function
    :name "claude-code-ide-mcp-call-function"
    :description "Call any Emacs Lisp function by name with JSON-encoded arguments. Use this instead of registering a dedicated MCP tool for every function. Pass the function name as a string and its positional arguments as a JSON array (e.g. \"[\\\"hello\\\", 42, true]\"). Pass \"[]\" for zero-argument calls. The return value is printed with prin1-to-string. Useful for calling utilities, querying state, or invoking helper functions defined in the Emacs config."
    :args '((:name "name"
             :type string
             :description "The name of the Emacs Lisp function to call (e.g. \"buffer-list\", \"claude-code-ide-mcp--function-source\")")
            (:name "args_json"
             :type string
             :description "JSON array of positional arguments, e.g. \"[\\\"my-function\\\"]\" or \"[]\". Strings, numbers, booleans, arrays, and objects are supported.")))

(provide 'claude-code-ide-extra-call-function)
;;; claude-code-ide-extra-call-function.el ends here
