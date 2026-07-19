---
name: emacs-file-analysis
description: "MUST invoke before reading any source file. Enforces file-outline → symbol-source → Read protocol. Never call Read as first tool on any source file."

---

# File Analysis Protocol

MUST follow this order. No exceptions.

```
file-outline → symbol-source → Read
```

**NEVER call `Read` as first tool on any source file.**

---

## Step 1 — `file-outline` (always first)

Call `file-outline(file_path)` for every target file.  
Returns: treesit availability + symbol list with line numbers **and signatures**.  
Multiple files: call in parallel.

## Step 2 — `symbol-source` (if treesit available)

Signatures from Step 1 are often sufficient — call `symbol-source` only when the full body is needed.  
Call `symbol-source(file_path, line)` using line from Step 1.  
Multiple symbols: call in parallel.

If truncated or wrong → Step 3.

## Step 3 — `Read` (last resort only)

Allowed only when:
1. `file-outline` was called for this file, AND
2. treesit unavailable OR `symbol-source` insufficient

Use specific line range. Never read whole file unless range unknown.

**NEVER call `Read` after `symbol-source` already returned the full body.** If `symbol-source` gave the complete function/type body, that is sufficient — do not call `Read` to "confirm" or see imports. Imports can be inferred from symbol usage.