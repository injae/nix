---
name: go-development
description: "Use for Go writing, review, or refactoring tasks. Apply idiomatic Go patterns and anti-patterns for error handling, concurrency, interfaces, dependencies, logging, and style. Auto-trigger on Go files, Go function implementation, and Go code quality discussions."
---

# Go Development Skill

## Do

### Error Handling
- Compare errors with `errors.Is` / `errors.As`; never use `==` or `.Error()` string matching.
- Wrap with context: `fmt.Errorf("...: %w", err)` (preserves chain).
- Handle errors immediately; never ignore.
- Custom error types should implement `Unwrap() error`.
- Combine multiple errors with `errors.Join()` (Go 1.20+).

### Interfaces
- Declare interfaces in consumer packages.
- Keep interfaces small/focused (1–3 methods).
- Name single-method interfaces with `-er` (`Reader`, `Closer`, `UserFinder`).
- Avoid Java-style names (`IUser`, `UserInterface`).

### Dependencies / Structs
- Inject dependencies via constructors (`NewXxx`).
- Do not share deps via globals (`var DB *sql.DB`).
- Pass `context.Context` as first parameter; never store context in struct fields.

### Concurrency
- Use `golang.org/x/sync/errgroup` over `sync.WaitGroup` when errors/cancellation matter.
- Always cap goroutines with `g.SetLimit(N)`.
- Recover panics inside goroutines and convert to errors (avoid service-wide crash).
- Use unexported struct pointers as context keys (`var key = &struct{}{}`).
- Define channel close ownership clearly (sender closes).

### Logging / Observability
- Use structured logging via `log/slog` (avoid `fmt.Printf` debug logs).
- Include operation, inputs, and error fields in error logs.
- Always set HTTP client timeouts.

### Code Style
- Run `gofmt` / `goimports`.
- Run `golangci-lint`.
- Use short lowercase package names (`httputil`, not `http_util`).
- Prefix error vars with `Err` (`ErrUserNotFound`).
- Use CamelCase constants (`DefaultTimeout`, not `DEFAULT_TIMEOUT`).

---

## Don’t

| Anti-Pattern | Reason | Correct Alternative |
|---|---|---|
| `err.Error() == "..."` | String dependency, fragile | Custom error type + `errors.As` |
| `panic(err)` in production | Crashes service | Return error and handle upstream |
| `_, _ = fn()` ignoring errors | Silent failure, data corruption | Explicit error handling |
| `var DB *sql.DB` global variable | Untestable, hidden coupling | Constructor injection |
| Storing `ctx context.Context` in struct | Stale context, goroutine leak | Pass as function parameter |
| `string` context key | Cross-package key collision | Unexported struct pointer |
| `sync.WaitGroup` for errorful workflows | No error/cancel propagation | `errgroup.WithContext` |
| God packages (`models`, `utils`) | Circular deps, bottlenecks | Split by capability |
| God interfaces | Hard to test, ISP violation | Compose small interfaces |
| `fmt.Printf` logging | Poor search/monitorability | `log/slog` structured logging |
| Captured loop var in goroutine (`go func(){ use(v) }()`) | All goroutines use final value | Shadow first: `v := v` |
| HTTP client without timeout | Infinite wait, goroutine leak | `&http.Client{Timeout: 30*time.Second}` |
| `time.After` in loop | Channel leak until GC | `time.NewTimer` + `defer t.Stop()` |

---

## Checklist (Code Review)

- [ ] Are all errors handled? (no ignored `_, err` patterns)
- [ ] Are `errors.Is` / `errors.As` used?
- [ ] Are errors wrapped with `%w` context where needed?
- [ ] Is `context.Context` first parameter?
- [ ] Are dependencies injected (no global deps)?
- [ ] Is `SetLimit` configured for goroutines?
- [ ] Is structured logging (`slog`) used?
- [ ] Are interfaces small and consumer-defined?
- [ ] Does code pass `gofmt`?
