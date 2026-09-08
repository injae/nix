---
name: emacs-file-analysis
description: "MUST invoke before reading any source file. Enforces file-outline → symbol-source → Read protocol. Never call Read as first tool on any source file."
user-invocable: false
---
# File Analysis Protocol

MUST follow order. No exception.

```
file-outline → symbol-source → Read
```

**NEVER call `Read` as first tool on any source file.**

---

## Step 1 — `file-outline` (always first)

Call `file-outline(file_path)` for every target file.
Give back: treesit availability + symbol list with line numbers **and signatures**.
Many file: pass as one comma-separated `file_path`.

`treesit: unavailable (imenu fallback)` still carry full symbol list — imenu give it. That outline good; only outline with **no symbol at all** mean fall back to `Read`.

## Step 2 — `symbol-source` (if the outline listed symbols)

Step 1 signature often enough — call `symbol-source` only when need full body.
Call `symbol-source(file_path, line)` with line from Step 1.
Many symbol: call parallel.

If truncated or wrong → Step 3.

## Step 3 — `Read` (last resort only)

Allow only when:
1. `file-outline` was called for this file, AND
2. outline list no symbol OR `symbol-source` not enough

Use specific line range. Never read whole file unless range unknown.

**NEVER call `Read` after `symbol-source` already returned the full body.** If `symbol-source` give whole function/type body, that enough — no call `Read` to "confirm" or see import. Import can guess from symbol use.