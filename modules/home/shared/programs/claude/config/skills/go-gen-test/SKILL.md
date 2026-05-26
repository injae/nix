---
name: go-gen-test
description: "Generate tests for Go files: create stubs first, then fill meaningful cases. Use Emacs go-gen-test-all when available; otherwise use manual template flow. Use testing/synctest for time-related tests."
user-invocable: true
---

# Go Test Generation

## Step 1 — Detect mode

Check whether `INSIDE_EMACS` is set or `mcp__ide__executeCode` is available.

Answer YES/NO:
- **YES** — Emacs active
- **NO** — standard environment

Before proceeding, state:
> "Emacs is **[active / not active]**. Reading: **[emacs.md / manual.md]**."

Both paths produce the same output format. Continue to Step 2 after stubs are generated.

---

## Step 1 (Emacs = YES) — Generate stubs via go-gen-test-all

Read `emacs.md` and follow it.

---

## Step 1 (Emacs = NO) — Generate stubs from template

Read `manual.md` and follow it.

---

## Step 2 — Fill test cases

### Package choice

| Situation | Package |
|-----------|---------|
| Need direct access to internal fields/types | `package <pkg>` (white-box) |
| Test only public API | `package <pkg>_test` (black-box) |

### Common patterns

**Constructor tests** — verify nil filtering, field values, slice length:
```go
{name: "registers tasks", ...},
{name: "filters nil tasks", ...},
{name: "all nil", ...},
```

**Error propagation** — cover error and non-error paths:
```go
{name: "propagates error", ..., wantErr: true},
{name: "no error on success", ..., wantErr: false},
```

**Context cancellation** — external cancellation should not be treated as error:
```go
{name: "external cancel returns no error", ..., wantErr: false},
```

### Time-related tests

If `time.After`, `time.Sleep`, or `time.Ticker` appears in the path, read `synctest.md` and follow it.

---

## Step 3 — Verify

```bash
go test ./... -run "Test<generated tests>" -v
go test ./...
```
