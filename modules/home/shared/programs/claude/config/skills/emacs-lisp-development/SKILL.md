---
name: emacs-lisp-development
description: "Use for Emacs Lisp writing, package development, or config changes. Apply GNU conventions and community style patterns/anti-patterns. Auto-trigger on .el files, Emacs config edits, and Elisp implementation tasks."
---

# Emacs Lisp Development Skill

## References

- GNU Emacs Lisp Reference (Tips & Conventions): https://www.gnu.org/software/emacs/manual/html_node/elisp/Tips.html
- GNU Coding Conventions: https://www.gnu.org/software/emacs/manual/html_node/elisp/Coding-Conventions.html
- bbatsov Emacs Lisp Style Guide: https://github.com/bbatsov/emacs-lisp-style-guide
- checkdoc: `M-x checkdoc` (built-in linter)
- flycheck-package: https://github.com/purcell/flycheck-package (package style checker)
- package-lint: https://github.com/purcell/package-lint

---

## Do

### File Header / Namespace
- First line must be: `;;; package-name.el --- Description -*- lexical-binding: t; -*-`
- Always set `lexical-binding: t` (performance + safety vs dynamic binding)
- Prefix all symbols (functions/variables/commands): `my-pkg-function-name`
- Include `(provide 'package-name)` at file end
- Add `;;; package-name.el ends here` as last line

### Function / Command Definitions
- Interactive commands must have `(interactive)` + docstring
- First docstring line must be a full sentence ending with a period
- Parameter names in docstrings should be ALLCAPS: `"Process FILENAME and return result."`
- Internal pure helpers use double-dash: `my-pkg--helper`
- Predicates end with `-p`: `my-pkg-valid-p`

### Dependency Management
- Declare dependencies explicitly at top: `(require 'cl-lib)`
- Macro deps: `(eval-when-compile (require 'foo))`
- Use autoload cookies where possible:
  `;;;###autoload`
- Use `cl-lib`, not deprecated `cl`

### Variables / Customization
- User-facing config vars: `defcustom` (docstring + :type + :group)
- Internal state: `defvar` (docstring required)
- Buffer-local vars: `(make-local-variable 'var)` or `(defvar-local var)`

### Error Handling
- Signal errors with `(error "message %s" arg)` (not `message` + `throw`)
- Use `condition-case` for conditional error handling
- Guarantee cleanup with `unwind-protect`

### Code Style
- Spaces only (no tabs)
- Follow `emacs-lisp-mode` default indentation
- Validate docstrings with `M-x checkdoc`
- Check compile warnings with `M-x byte-compile-file`

---

## Don’t

### Namespace / Symbols
| Anti-pattern | Reason | Correct Alternative |
|---|---|---|
| Global symbol without prefix `(defun helper ...)` | Conflicts with other packages | `(defun my-pkg-helper ...)` |
| Redefining common names like `cadr`, `caddr` | System-wide conflicts | Add prefix: `my-pkg-cadr` |
| Omitting `lexical-binding: t` | Unintended dynamic binding capture | Always set in header |

### Load / Configuration Side Effects
| Anti-pattern | Reason | Correct Alternative |
|---|---|---|
| Changing Emacs settings on package load | Load-order dependent, unpredictable | Provide explicit setup functions |
| Using `eval-after-load` in a library | Silently changes behavior of other files | Use only in user config |
| Quietly patching package functions with `advice-add` | Hard to debug, fragile on upgrades | Use hooks or explicit wrappers |
| Direct use of `cl` library | Deprecated | Use `cl-lib` (`cl-loop`, `cl-defun`, etc.) |

### I/O / Buffer Manipulation
| Anti-pattern | Reason | Correct Alternative |
|---|---|---|
| `next-line` / `previous-line` in code | Affected by user settings | `forward-line` |
| `beginning-of-buffer` / `end-of-buffer` in code | Runs user hooks | `(goto-char (point-min))` |
| `replace-string` / `replace-regexp` in code | Interactive-only commands | `while` + `search-forward` + `replace-match` |
| Printing messages with `princ` | Not shown in echo area | `(message "...")` |
| Using `beep` / `sleep-for` for errors | Non-standard, poor UX | `(error "...")` |

### Performance
| Anti-pattern | Reason | Correct Alternative |
|---|---|---|
| Calling `length` repeatedly on large lists | O(n) each call | Compute once and store |
| Manual iteration instead of `memq`/`assq` | Slow and verbose | Use built-in search functions |
| Shipping non-byte-compiled code | Slower execution | Distribute `.elc` or run `byte-compile-file` |

---

## Checklist (Code Review)

- [ ] File header includes `;;; -*- lexical-binding: t; -*-`?
- [ ] All symbols use package prefix?
- [ ] All functions/variables have docstrings?
- [ ] Interactive commands include `(interactive)`?
- [ ] `(provide 'package-name)` present?
- [ ] Using `cl-lib` (not `cl`)?
- [ ] `M-x checkdoc` passes?
- [ ] No byte-compilation warnings?
- [ ] No load-time global side effects?
