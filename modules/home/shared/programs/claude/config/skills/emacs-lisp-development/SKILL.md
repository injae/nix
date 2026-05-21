---
name: emacs-lisp-development
description: "Must be used when writing Emacs Lisp code, developing packages, or modifying configuration files. Applies patterns and anti-patterns based on GNU official coding conventions and community style guides. Automatically triggered when opening .el files, modifying Emacs configuration, or implementing Elisp functions."
---

# Emacs Lisp Development Skill

## Official References

- GNU Emacs Lisp Reference (Tips & Conventions): https://www.gnu.org/software/emacs/manual/html_node/elisp/Tips.html
- GNU Coding Conventions: https://www.gnu.org/software/emacs/manual/html_node/elisp/Coding-Conventions.html
- bbatsov Emacs Lisp Style Guide: https://github.com/bbatsov/emacs-lisp-style-guide
- checkdoc: `M-x checkdoc` (built-in linter)
- flycheck-package: https://github.com/purcell/flycheck-package (package style checker)
- package-lint: https://github.com/purcell/package-lint

---

## Patterns (What to Do)

### File Header / Namespace
- First line of every file must be the standard header: `;;; package-name.el --- Description -*- lexical-binding: t; -*-`
- `lexical-binding: t` must always be set — superior performance and safety over dynamic binding
- All symbols (functions, variables, commands) must have a package prefix: `my-pkg-function-name`
- Include `(provide 'package-name)` at the end of the file
- Add `;;; package-name.el ends here` as the last line

### Function / Command Definitions
- Interactive commands must include both an `(interactive)` declaration and a docstring
- Docstring first line must be a complete sentence ending with a period
- Parameters in docstrings should be written in ALLCAPS: `"Process FILENAME and return result."`
- Pure helper functions should use `--` double-dash to indicate internal use: `my-pkg--helper`
- Predicate functions use `-p` suffix: `my-pkg-valid-p`

### Dependency Management
- Explicitly `require` dependencies at the top of the file: `(require 'cl-lib)`
- Macro dependencies should use `(eval-when-compile (require 'foo))`
- Use `autoload` cookies where possible to load only when needed:
  `;;;###autoload`
- Use `cl-lib` instead of `cl` (`cl` is deprecated)

### Variables / Customization
- User-facing configuration variables should be defined with `defcustom` (docstring + :type + :group)
- Internal state should use `defvar` (docstring required)
- Buffer-local variables should use `(make-local-variable 'var)` or `(defvar-local var)`

### Error Handling
- Signal errors with `(error "message %s" arg)` (do not use `message` + `throw`)
- Use `condition-case` for conditional error handling
- Guarantee resource cleanup with `unwind-protect`

### Code Style
- Indentation: spaces only, no tabs
- Follow Emacs `emacs-lisp-mode` default indentation
- Check docstring style with `M-x checkdoc`
- Verify compilation warnings with `M-x byte-compile-file`

---

## Anti-Patterns (What Not to Do)

### Namespace / Symbols
| Anti-pattern | Reason | Correct Alternative |
|---|---|---|
| Global symbol without prefix `(defun helper ...)` | Conflicts with other packages | `(defun my-pkg-helper ...)` |
| Redefining common names like `cadr`, `caddr` | System-wide conflicts | Add prefix: `my-pkg-cadr` |
| Not setting `lexical-binding: t` | Unintended variable capture with dynamic binding | Always set in header |

### Load / Configuration Side Effects
| Anti-pattern | Reason | Correct Alternative |
|---|---|---|
| Changing Emacs settings when package loads | Load-order dependent, unpredictable | Provide explicit setup functions |
| Using `eval-after-load` inside a library | Silently alters behavior of other files | Use only in user configuration |
| Quietly patching other package functions with `advice-add` | Hard to debug, fragile on upgrades | Use hooks or explicit wrappers |
| Direct use of `cl` library | Deprecated | `cl-lib` (`cl-loop`, `cl-defun`, etc.) |

### I/O / Buffer Manipulation
| Anti-pattern | Reason | Correct Alternative |
|---|---|---|
| `next-line` / `previous-line` in code | Affected by user settings | `forward-line` |
| `beginning-of-buffer` / `end-of-buffer` in code | Runs user hooks | `(goto-char (point-min))` |
| `replace-string` / `replace-regexp` in code | Interactive-only commands | `while` + `search-forward` + `replace-match` |
| Printing messages with `princ` | Not displayed in echo area | `(message "...")` |
| Using `beep` / `sleep-for` for error reporting | Non-standard, poor user experience | `(error "...")` |

### Performance
| Anti-pattern | Reason | Correct Alternative |
|---|---|---|
| Calling `length` repeatedly on large lists | O(n) on every call | Calculate once and store in variable |
| Manual iteration instead of `memq`/`assq` | Slow and verbose | Use built-in search functions |
| Distributing non-byte-compiled code | Slow execution | Distribute `.elc` or run `byte-compile-file` |

---

## Checklist (For Code Review)

- [ ] Does the file have a `;;; -*- lexical-binding: t; -*-` header?
- [ ] Do all symbols have a package prefix?
- [ ] Do all functions and variables have a docstring?
- [ ] Do interactive commands have `(interactive)`?
- [ ] Is `(provide 'package-name)` present?
- [ ] Is `cl-lib` used instead of `cl`?
- [ ] Does `M-x checkdoc` pass?
- [ ] Are there no byte-compilation warnings?
- [ ] Are there no side effects on load (global setting changes)?