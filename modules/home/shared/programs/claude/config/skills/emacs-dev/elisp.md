# Emacs Lisp File Guidelines

When the current file's major-mode is `emacs-lisp-mode` (`.el` extension), follow this step-by-step sequence for every edit. Each step requires an explicit evaluate → commit → execute before moving to the next.

---

## Step 1 — Find the target symbol

Call `file-outline` with the absolute file path. Returns the full symbol list with line numbers.

`emacs-lisp-mode` does not use tree-sitter — there is no `emacs-lisp-ts-mode`. `file-outline` always reports `treesit: unavailable`, and `symbol-source` always uses the 30-line fallback read. Skip the treesit check and proceed directly to Step 2.

Commit out loud before proceeding:
> "Target `[symbol]` is at line [N]. Next tool: **symbol-source** at line [N]."

**Never use `Read` to explore an elisp file without first calling `file-outline`.**

---

## Step 2 — Read the symbol source

Call `symbol-source(file_path, line)` to get the exact declaration.

Answer YES or NO — is the source complete?
- **YES** → proceed to Step 3.
- **NO** (truncated) → commit out loud:
  > "symbol-source insufficient. Falling back to **Read** at lines [start–end] only."

Additional tools available for elisp-specific navigation:

| Task | Tool | Fallback |
|------|------|----------|
| Find where a symbol is defined | `describe-symbol` | `lsp-def`, then `xref-apropos` |
| Find all call sites | `xref-refs` | `elisp-refs` |
| Understand a built-in / package function | `describe-symbol` | — |
| List callees of a function | `elisp-callees` | — |

### Elisp symbol-to-file lookup (sequential constraint)

Every "where is Elisp symbol X defined?" query — whether for a project `.el` file, a loaded package, or an Emacs built-in — requires this sequence. Do NOT call `Bash find` before completing it.

**Step 1 — Evaluate: Is the exact symbol name known?**

Call `describe-symbol(name)`. Returns `Defined in: /path/to/file.el` for any loaded symbol, including elpaca, straight, nix-store, and built-in packages.

Answer YES or NO:
- **YES** (symbol found) → commit out loud:
  > "Symbol `[name]` defined in `[path]`. Next: **file-outline** or **symbol-source**."
- **NO** (not found / uncertain name) → Step 2.

**Step 2 — Evaluate: Is a partial name known?**

Call `xref-apropos(pattern)`. Returns all matching loaded symbols with file locations.

Commit out loud:
> "Best match: `[symbol]` at `[path]`. Proceeding with **describe-symbol** to confirm."

**Gate check — before `Bash find` or `grep` on `.el` files, confirm:**
1. `describe-symbol` was called → symbol not found or not loaded
2. `xref-apropos` was called → no matches
3. Only then: Bash is justified

`describe-symbol` covers **all loaded Emacs packages** (elpaca/straight/nix-store/built-in). `find *.el` is never faster or more accurate when the symbol name is known.

---

## Step 3 — Edit

Apply the change with the `Edit` tool.

### Preventing paren mistakes

**When restructuring (adding/removing wrappers) — think in delta, not absolute count**

Before writing `new_string`, calculate explicitly:
- Levels removed: -N
- Levels added: +M
- delta = M - N → if delta = 0, the closing paren count on the last line does not change

**Before writing closing parens — list open forms in reverse order**

```
; e.g. with-selected-window → cond-clause → cond → let → if → dolist → unless → defun
; = 8 forms → ))))))))
```

**Split structural changes from content changes** — don't combine wrapper reorganization and body edits in a single `Edit` call.

---

## Step 4 — Verify parenthesis balance

Run the Python script directly via Bash:

```bash
python3 ~/.claude/hooks/elisp-check-parens.py /path/to/file.el
```

- `"balanced"` → Step 5 진행
- error 메시지 (line/column 포함) → 해당 위치 수정 후 Step 4 반복

---

## Step 4.5 — Verify condition-case structure (when wrapping a macro call)

The Python script only verifies paren balance — it cannot catch structural errors. When `condition-case` wraps a macro call, a single misplaced `)` can absorb the error handler into the macro body, leaving `condition-case` with no handlers. The file still reports "balanced".

**Trigger**: edited any function where `condition-case` wraps a macro call.

### Diagnostic pattern

```elisp
(with-temp-buffer
  (insert-file-contents "/path/to/file.el")
  (goto-char (point-min))
  (search-forward "(defun FUNCTION-NAME")
  (backward-up-list 1)
  (let* ((form (read (current-buffer)))
         (body (nth 4 form))         ; first body form (after docstring)
         (handlers (cddr body)))     ; protected-form + handler clauses of condition-case
    (list 'handler-conditions (mapcar #'car handlers))))
```

**Correct**: `(handler-conditions (MACRO-NAME error))` — `error` handler is present  
**Bug**: `(handler-conditions (MACRO-NAME))` — no `error` handler

### Root cause and fix

One missing `)` before the handler clause causes the `(error ...)` handler to be spliced into the macro's `,@body`:

```elisp
;; Bug: macro call not closed before the handler
         ...symbols "\n"))))))        ; 6 closes — macro call still open
    (error (format ... err))))))      ; handler absorbed into macro body; condition-case catches nothing

;; Fix: close the macro call first
         ...symbols "\n")))))))       ; 7 closes — macro call closed here
    (error (format ... err)))))       ; handler at the correct level
```

After fixing, re-run the diagnostic to confirm `error` appears in `handler-conditions`.

---

## Step 5 — Format buffer

Call `format-buffer` with `file_path` to reformat the file via apheleia before loading.

This ensures the loaded code has correct indentation and the file on disk matches what Emacs shows.

---

## Step 6 — Test interactively (if applicable)

Call `elisp-load` with `file_path` to reload the entire file into the running Emacs session.

---

## Creating new MCP tools

When adding a new tool to the claude-code-ide setup, follow the `emacs-mcp-dev` skill conventions:
- File: `config/lisp/claude-code-ide/extras/claude-code-ide-extra-{domain}.el` — append to the matching domain file (or create a new one + add `require` to the aggregator)
- Public functions: `claude-code-ide-mcp-{verb}-{noun}`, private helpers `claude-code-ide-mcp--{name}`
- Every public function body wrapped in `condition-case err`
- Read-only tools: `(let ((inhibit-redisplay t)) ...)` outside `with-current-buffer`
- No registration step — file is already `require`d from `config/module/+ai.el`
- After adding: update `emacs-dev/navigation.md` tool table and `max_results` count in `SKILL.md`