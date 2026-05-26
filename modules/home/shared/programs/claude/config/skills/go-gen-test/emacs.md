# Stub Generation — Emacs Mode

> **GATE**: Do NOT write any test code manually. Do NOT create `_test.go` files by hand.
> Complete Steps 1–3 below first. Only after stubs exist in the buffer may you fill test cases.

## Step 1 — Navigate to the target file

```
goto-line(file_path, line=1)
```

## Step 2 — Run go-gen-test-all in the background

Override `completing-read-multiple` with `cl-letf` to bypass the consult UI and auto-select all functions:

```elisp
(with-current-buffer "<filename>"
  (cl-letf (((symbol-function 'completing-read-multiple)
             (lambda (_prompt collection &rest _args)
               (if (listp collection) collection (all-completions "" collection)))))
    (go-gen-test-all)))
```

Run via `mcp__ide__executeCode`. A return value of `#<buffer ...test.go>` means success.

## Step 3 — Read the generated stubs

Use `file-outline` on the generated `_test.go` to get the symbol list and line numbers.
Then return to **Step 2** in `SKILL.md` to fill in the test cases.