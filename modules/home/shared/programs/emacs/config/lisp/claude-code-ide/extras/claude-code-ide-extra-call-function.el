;;; claude-code-ide-extra-call-function.el --- MCP tool: call any Emacs function by name -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(require 'claude-code-ide-mcp-server)

(defvar claude-code-ide-mcp--blocked-functions
  '(kill-emacs save-buffers-kill-emacs save-buffers-kill-terminal)
  "Functions that `claude-code-ide-mcp-call-function' refuses to invoke.")

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

(defun claude-code-ide-mcp-call-function (name args)
  "Call Emacs function NAME with positional ARGS.
ARGS is a vector decoded from the JSON array by the MCP server.
Each element is converted to Elisp via `claude-code-ide-mcp--json-to-elisp'.
Omit ARGS for zero-argument calls.
Functions in `claude-code-ide-mcp--blocked-functions' and interactive
commands are refused."
  (condition-case err
      (let ((sym (intern-soft name)))
        (cond
         ((not sym)
          (format "Symbol '%s' not found." name))
         ((not (fboundp sym))
          (format "'%s' is not a function." name))
         ((memq sym claude-code-ide-mcp--blocked-functions)
          (format "'%s' is blocked for security reasons." name))
         ((commandp sym)
          (format "'%s' is an interactive command and cannot be called via call-function." name))
         (t
          (let* ((arg-list (when args
                             (mapcar #'claude-code-ide-mcp--json-to-elisp
                                     (seq-into args 'list))))
                 (result (apply sym arg-list)))
            (prin1-to-string result)))))
    (error (format "Error calling '%s': %s" name (error-message-string err)))))

(claude-code-ide-make-tool
    :function #'claude-code-ide-mcp-call-function
    :name "call_fn"
    :description "Call any Emacs Lisp function by name with positional arguments. Use this instead of registering a dedicated MCP tool for every function. The return value is printed with prin1-to-string. Useful for calling utilities, querying state, or invoking helper functions defined in the Emacs config."
    :args '((:name "name"
             :type string
             :description "The name of the Emacs Lisp function to call (e.g. \"buffer-list\", \"claude-code-ide-mcp--function-source\")")
            (:name "args"
             :type array
             :optional t
             :description "Positional arguments as a JSON array, e.g. [\"hello\", 42, true]. Omit for zero-argument calls.")))

(provide 'claude-code-ide-extra-call-function)
;;; claude-code-ide-extra-call-function.el ends here
