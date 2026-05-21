# testing/synctest — Time Bubble Pattern (Go 1.26+)

## When to use

Use when `time.After`, `time.Sleep`, or `time.Ticker` appears in the test path.

## Basic pattern

```go
package foo

import (
    "context"
    "testing"
    "testing/synctest"
    "time"
)

func TestFoo_Timing(t *testing.T) {
    t.Run("case name", func(t *testing.T) {
        synctest.Test(t, func(t *testing.T) {
            start := time.Now()

            // Use large fake durations — they run instantly inside the bubble.
            // Replace 100ms → 5*time.Second. Equivalent, but intent is clearer.
            err := subject.Run(context.Background())

            assert.Equal(t, 5*time.Second, time.Since(start))
            assert.NoError(t, err)
        })
    })
}
```

## External cancel

When a cancel goroutine must run concurrently, start it inside the bubble:

```go
synctest.Test(t, func(t *testing.T) {
    ctx, cancel := context.WithCancel(context.Background())
    go func() {
        time.Sleep(2 * time.Second) // advances fake clock instantly
        cancel()
    }()
    err := subject.Run(ctx)
    assert.NoError(t, err)
})
```

## Key rules

| Rule | Detail |
|------|--------|
| Fake clock advances when… | all goroutines in the bubble are durably blocked |
| Durably blocking | `time.Sleep`, channel ops on bubble channels, `sync.WaitGroup.Wait`, `sync.Cond.Wait` |
| NOT durably blocking | mutex locks, network I/O, syscalls |
| Channels/timers/contexts | belong to the bubble if created inside it |
| `synctest.Wait()` | blocks until all goroutines are durably blocked — use after starting goroutines to assert intermediate state |