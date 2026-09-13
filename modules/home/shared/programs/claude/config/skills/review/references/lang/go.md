# Go Language Checklist

> For full Go patterns and anti-patterns, see the `go-development` skill. This file contains only review-specific checklist items (per-stage additions).

Add the items below to the shared stage checklists.

---

## Stage 1 — Architecture

**Embed shadowing**
- Does the outer struct declare a field with **the same name** as one in an embedded struct?
  - `p.Field` then quietly hides the embedded type's field of that name, so one side is written
    and the other is read.
  - Fix: avoid the name collision, or replace the embed with an explicit field plus accessors.

---

## Stage 2 — Security

- Is `crypto/rand` used instead of `math/rand` for security-relevant randomness?
- Is untrusted data decoded with `encoding/gob`?

---

## Stage 3 — Resource management

**Memory**
- Goroutine leak: is any goroutine started with no exit condition?
- Can a slice grow without bound (an append loop, …)?

**Files & I/O**
- Is the `defer f.Close()` pattern used?
- Is `defer` used inside a loop, so files stay open until the function returns?

**Database**
- Is `rows.Close()` missing (`defer rows.Close()` preferred)?
- Is the error from `db.QueryRow().Scan()` ignored?

**Network**
- Is `defer resp.Body.Close()` called on every path?

**OS resources**
- Is `time.Ticker` / `time.Timer` stopped with `Stop()` after use?
- Is `cmd.Wait()` called on child processes (no zombies)?

---

## Stage 4 — Concurrency & performance

**Races**
- Is there a pattern `go vet -race` would catch?
  - A map shared between goroutines without `sync.Map` or a mutex
  - Concurrent access to a slice or a struct field
  - Loop variable captured in a closure (the pre-Go 1.22 pattern)

**Deadlock**
- Do channel operations wait on each other (unbuffered channel deadlock)?
- Does the code take `Lock` while holding `RLock`?

**Lock granularity**
- Is `Mutex` used where `RWMutex` would serve a read-only operation?

**Goroutine management**
- Does `context.Context` propagate through the whole goroutine chain?
- Is `WaitGroup.Add()` called before the goroutine starts (Add/Done/Wait order)?
- Is a panic inside a goroutine recovered?
- Can a receiver block forever because a channel is never closed?

**Atomicity**
- Is a plain variable accessed concurrently where `sync/atomic` belongs?
- On 32-bit systems, is a 64-bit atomic misaligned (struct field layout)?

**Performance**
- Are strings concatenated with `+` in a loop instead of `strings.Builder`?
- Is `regexp.Compile()` called on every iteration?
- Is reflection (the `reflect` package) used on a hot path?
