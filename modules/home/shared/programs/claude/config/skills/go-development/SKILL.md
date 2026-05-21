---
name: go-development
description: "Must be used when writing, reviewing, or refactoring Go code. Applies idiomatic Go patterns and anti-patterns for error handling, concurrency, interfaces, and logging. Triggers automatically when opening a Go file, implementing a Go function, or discussing Go code quality issues."
---

# Go Development Skill

## Official References

- Effective Go: https://go.dev/doc/effective_go
- Go Code Review Comments: https://go.dev/wiki/CodeReviewComments
- Go Style Guide (Google): https://google.github.io/styleguide/go/
- Uber Go Style Guide: https://github.com/uber-go/guide/blob/master/style.md
- Go Proverbs: https://go-proverbs.github.io/

---

## Patterns (Do's)

### Error Handling
- Compare errors with `errors.Is` / `errors.As` — never use `==` or `.Error()` string comparison
- Add context to errors with `fmt.Errorf("...: %w", err)` (preserves chain)
- Handle errors immediately and never ignore them
- Custom error types must implement `Unwrap() error`
- Combine multiple errors with `errors.Join()` (Go 1.20+)

### Interfaces
- Declare interfaces in the consumer package
- Use small, focused interfaces with 1–3 methods
- Name single-method interfaces with the `-er` suffix (`Reader`, `Closer`, `UserFinder`)
- Avoid Java-style names like `IUser` or `UserInterface`

### Dependencies / Structs
- Inject dependencies explicitly in constructors (`NewXxx`)
- Never share dependencies via global variables (`var DB *sql.DB`)
- Always pass `context.Context` as the first parameter; never store it in a struct field

### Concurrency
- Use `golang.org/x/sync/errgroup` instead of `sync.WaitGroup` (error handling + context cancellation)
- Always cap goroutine count with `g.SetLimit(N)`
- Catch panics inside goroutines with `recover()` and convert to errors (prevent service crashes)
- Use unexported struct pointers as context keys (`var key = &struct{}{}`)
- Clarify channel close ownership (the sender closes)

### Logging / Observability
- Use `log/slog` for structured logging (no `fmt.Printf` debug logs)
- Include operation, input values, and error fields in error logs
- Always set timeouts on HTTP clients

### Code Style
- Always apply `gofmt` / `goimports`
- Use `golangci-lint` for static analysis
- Package names should be short, lowercase words (no underscores or capitals: `httputil` not `http_util`)
- Prefix error variable names with `Err`: `ErrUserNotFound`
- Use CamelCase for constants (`DefaultTimeout`, not `DEFAULT_TIMEOUT`)

---

## Anti-Patterns (Don'ts)

| Anti-Pattern | Reason | Correct Alternative |
|---|---|---|
| `if err == ErrFoo` | Fails with wrapped errors | `errors.Is(err, ErrFoo)` |
| `err.Error() == "..."` | String dependency, extremely fragile | Custom error type + `errors.As` |
| `panic(err)` in production | Crashes entire service | Return error and handle upstream |
| `_, _ = fn()` ignoring errors | Silent failure, data corruption | Explicit error handling |
| `var DB *sql.DB` global variable | Untestable, hidden coupling | Constructor injection |
| Storing `ctx context.Context` in struct | Stale context, goroutine leak | Pass as function parameter |
| `string` type context key | Collision across packages | Unexported struct pointer |
| `sync.WaitGroup` (with errors) | Cannot handle errors/cancellation | `errgroup.WithContext` |
| Large god packages (`models`, `utils`) | Circular deps, build bottlenecks | Split into capability-based packages |
| Large god interfaces | Untestable, violates ISP | Compose small interfaces |
| `fmt.Printf` logging | Not searchable, not monitorable | `log/slog` structured logging |
| Capturing loop variable in goroutine (`go func() { use(v) }()`) | All goroutines use the last value | Shadow with `v := v` before use |
| HTTP client without timeout | Infinite wait, goroutine leak | `&http.Client{Timeout: 30*time.Second}` |
| `time.After` in a loop | Channel leak until GC | `time.NewTimer` + `defer t.Stop()` |

---

## Checklist (Code Review)

- [ ] Are all errors handled? (no `_, err` patterns)
- [ ] Are `errors.Is` / `errors.As` used?
- [ ] Is context added to errors with `%w`?
- [ ] Is Context the first parameter?
- [ ] Are dependencies injected without global variables?
- [ ] Is SetLimit set for goroutines?
- [ ] Is structured logging (`slog`) used?
- [ ] Are interfaces small and defined on the consumer side?
- [ ] Does the code pass `gofmt`?