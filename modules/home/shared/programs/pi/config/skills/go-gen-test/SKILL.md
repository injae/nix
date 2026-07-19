---
name: go-gen-test
description: "Generate tests for Go files: create stubs first, then fill meaningful cases. Use Emacs go-gen-test-all when available; otherwise use manual template flow. Use testing/synctest for time-related tests."

---

# Go Test Generation

## Step 1 — Detect mode

Check whether `INSIDE_EMACS` is set or an Emacs MCP `executeCode` tool is available in Pi.

YES/NO:
- **YES** — Emacs active
- **NO** — standard environment

State before proceeding:
> "Emacs is **[active / not active]**. Reading: **[emacs.md / manual.md]**."

Both paths produce same output. Continue to Step 2 after stubs generated.

---

## Step 1 (Emacs = YES) — Generate stubs via go-gen-test-all

Read `emacs.md` and follow it.

---

## Step 1 (Emacs = NO) — Generate stubs from template

Read `manual.md` and follow it.

---

## Step 1.5 — Stub audit (before filling)

Scan every generated stub for anti-patterns. Fix **before** writing test cases — broken stubs waste effort.

### Anti-pattern 1 — Unresolved generic type param

**Signal:** non-generic test function has field typed `Foo[T]` (e.g., `endecoder.EnDecoder[T]`, `Option[T]`).  
**Effect:** compile error — `T` undefined outside generic context.  
**Fix:** replace `[T]` with concrete type (`[int]`, `[string]`, etc.) throughout that test function.

### Anti-pattern 2 — `reflect.DeepEqual` on function values

**Signal:** `want Option[T]` or `want GetOption` in table-driven test; comparison is `reflect.DeepEqual(got, tt.want)`.  
**Effect:** always false — Go can't compare function values.  
**Fix:** delete table struct. Apply option/func to real target struct, assert **effect**:
```go
func TestWithFoo(t *testing.T) {
    s := &MyStruct{}
    WithFoo("bar")(s)
    if s.foo != "bar" {
        t.Errorf("WithFoo() foo = %q, want \"bar\"", s.foo)
    }
}
```

### Anti-pattern 3 — `reflect.DeepEqual` on structs with function or interface fields

**Signal:** constructor test does `reflect.DeepEqual(got, tt.want)` where returned struct contains function fields (`IDFunc`, `EnDecoder`, etc.).  
**Effect:** always false — functions and interface values not comparable by DeepEqual.  
**Fix:** assert individual observable properties:
```go
if got.client != client { t.Error(...) }
if got.enDecoder == nil { t.Error(...) }
if got.streamIDFunc("x") != "stream:x" { t.Error(...) }
```

### Anti-pattern 4 — Unused imports in stubs

**Signal:** `_ "embed"` or `"reflect"` imported in test file that doesn't use them.  
**Fix:** remove before filling to avoid compile noise.

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

**Context cancellation** — external cancel not treated as error:
```go
{name: "external cancel returns no error", ..., wantErr: false},
```

### Time-related tests

`time.After`, `time.Sleep`, or `time.Ticker` in path → read `synctest.md` and follow it.

---

## Step 3 — Verify

```bash
go test ./... -run "Test<generated tests>" -v
go test ./...
```