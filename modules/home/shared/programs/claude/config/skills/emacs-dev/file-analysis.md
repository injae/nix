# File Analysis Flow

Every file analysis requires an explicit evaluate → commit → execute sequence. You must not call the next tool until you have answered the evaluation question and committed to the path. One completed sequence does NOT cover other files — each file requires its own pass.

---

## Step 1 — Evaluate: Is tree-sitter available?

Call `file-outline` with the absolute file path. Returns `major-mode`, `treesit` availability, and the full symbol list with line numbers in one call. Opens the file in the background if needed.

Answer YES or NO:
- **YES** if `treesit: available`
- **NO** otherwise

Commit out loud before proceeding:
> "Tree-sitter is **[available / not available]** for `[file]`. Next tool: **[symbol-source / Read]**."

---

## Step 2 (tree-sitter = YES) — Evaluate: What source do I need?

The symbol list from Step 1 contains line numbers. Identify the target symbol and its line number.

Commit out loud before proceeding:
> "Target `[symbol]` is at line [N]. Next tool: **symbol-source** at line [N]."

**The line numbers from `file-outline` are inputs to `symbol-source`. They are NOT permission to call `Read`.**

---

## Step 3 (tree-sitter = YES) — Get source

Call `symbol-source(file_path, line)`. The tool uses tree-sitter internally to find the exact declaration bounds and returns the full source.

Answer YES or NO — is the returned source complete and correct?
- **YES** → done.
- **NO** (truncated or wrong) → commit out loud before proceeding:
  > "symbol-source insufficient. Falling back to **Read** at lines [start–end] only."

---

## Step 4 — Read (only if Step 3 = NO, or tree-sitter unavailable)

Call `Read` with a specific line range. Do not read the whole file unless the range cannot be determined.

---

**Gate check — before calling `Read`, you must confirm:**
1. `file-outline` was called for this file → structure obtained
2. If tree-sitter available: `symbol-source` was called → result was insufficient
3. Only then: `Read` is justified

If you cannot confirm steps 1–2, you must go back and complete them first.