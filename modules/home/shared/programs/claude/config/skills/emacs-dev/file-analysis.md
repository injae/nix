# File Analysis Flow

Tool selection rules for reading source code. Follow in order; skip levels only when stated.

---

## Step 1 — `file-outline` first (always)

Call `file-outline` for each target file. Returns `treesit` availability + symbol list with line numbers.  
Multiple files: call in parallel.

---

## Step 2 — `symbol-source` if tree-sitter available

Use the line number from Step 1 to call `symbol-source(file_path, line)`.  
Multiple symbols/files: call in parallel.

If result is truncated or wrong → fall through to Step 3.

---

## Step 3 — `Read` as last resort only

Allowed only when:
1. `file-outline` was called for this file, AND
2. tree-sitter unavailable OR `symbol-source` result was insufficient

Use a specific line range. Do not read the whole file unless range is unknown.

---

**Gate:** never call `Read` as first tool. Order: `file-outline` → `symbol-source` → `Read`.