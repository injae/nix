# Emacs Lisp File Guidelines

When the current file's major-mode is `emacs-lisp-mode` (`.el` extension), follow this step-by-step sequence for every edit. Each step requires an explicit evaluate → commit → execute before moving to the next.

---

## Step 1 — Find the target symbol

Call `file-outline` with the absolute file path. Returns the full symbol list with line numbers.

`emacs-lisp-mode` always has tree-sitter available — skip the treesit check.

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
| Find where a symbol is defined | `lsp-find-definition` or `describe-symbol` | `xref-find-apropos` |
| Find all call sites | `xref-find-references` | `elisp-find-references` |
| Understand a built-in / package function | `describe-symbol` | — |
| List callees of a function | `elisp-callees` | — |

---

## Step 3 — Edit

Apply the change with the `Edit` tool.

---

## Step 4 — Verify parenthesis balance

Call `mcp__emacs-tools__claude-code-ide-mcp-elisp-check-parens` with `file_path`.

- `"balanced"` → Step 5 진행
- error 메시지 (mismatch 위치 포함) → 해당 위치 수정 후 Step 4 반복

---

## Step 5 — Test interactively (if applicable)

Call `mcp__emacs-tools__claude-code-ide-mcp-elisp-load-file` with `file_path`으로 전체 파일 재로드.

---

## Creating new MCP tools

When adding a new tool to the claude-code-ide setup, follow the `emacs-mcp-dev` skill conventions:
- File: `config/module/mcp/+{name}.el`
- Public functions: `claude-code-ide-mcp-{verb}-{noun}`, private helpers `claude-code-ide-mcp--{name}`
- Every public function body wrapped in `condition-case err`
- Read-only tools: `(let ((inhibit-redisplay t)) ...)` outside `with-current-buffer`
- Register in `config/module/+ai.el` `load-modules-with-list`
- After adding: update `emacs-dev/navigation.md` tool table and `max_results` count in `SKILL.md`