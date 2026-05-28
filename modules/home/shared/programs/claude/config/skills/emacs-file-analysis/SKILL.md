---
name: emacs-file-analysis
description: "Use when reading or inspecting source files in emacs-dev context — struct/type lookup, function body read, any source file access. Enforces file-outline → symbol-source → Read protocol. MUST activate before any file read in an Emacs session."
user-invocable: false
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
Returns: treesit availability + symbol list with line numbers.  
Multiple files: call in parallel.

## Step 2 — `symbol-source` (if treesit available)

Call `symbol-source(file_path, line)` using line from Step 1.  
Multiple symbols: call in parallel.

If truncated or wrong → Step 3.

## Step 3 — `Read` (last resort only)

Allowed only when:
1. `file-outline` was called for this file, AND
2. treesit unavailable OR `symbol-source` insufficient

Use specific line range. Never read whole file unless range unknown.