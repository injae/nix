---
name: go-gen-test
description: "Generate tests for a Go file. Runs Emacs go-gen-test-all in the background to create stubs, then fills in meaningful test cases. Time-related tests use testing/synctest. Use this skill whenever the user asks to write or generate tests for a Go file."
user-invocable: true
---

# Go Test Generation

## Step 1 — Detect mode

Check: is `INSIDE_EMACS` set or `mcp__ide__executeCode` available?

Answer YES or NO:
- **YES** — Emacs is active
- **NO** — standard environment

Commit out loud before proceeding:
> "Emacs is **[active / not active]**. Reading: **[emacs.md / manual.md]**."

Both guides produce the same output format. Continue with Steps 2–4 below after generating the stubs.

---

## Step 1 (Emacs = YES) — Generate stubs via go-gen-test-all

Read `emacs.md` and follow its steps.

---

## Step 1 (Emacs = NO) — Generate stubs from template

Read `manual.md` and follow its steps.

---

## Step 2 — Fill in test cases

### Package choice

| Situation | Package |
|-----------|---------|
| Need direct access to internal fields/types | `package <pkg>` (white-box) |
| Testing only the public API | `package <pkg>_test` (black-box) |

### Common patterns

**Constructor tests** — verify nil filtering, field values, slice length:
```go
{name: "registers tasks", ...},
{name: "filters nil tasks", ...},
{name: "all nil", ...},
```

**Error propagation** — cover both error and non-error paths:
```go
{name: "propagates error", ..., wantErr: true},
{name: "no error on success", ..., wantErr: false},
```

**Context cancellation** — confirm external cancellation is not treated as an error:
```go
{name: "external cancel returns no error", ..., wantErr: false},
```

### Time-related tests

When `time.After`, `time.Sleep`, or `time.Ticker` appears in the test path,
read `synctest.md` and follow its guidelines.

---

## Step 3 — Verify

```bash
go test ./... -run "Test<generated tests>" -v
go test ./...
```