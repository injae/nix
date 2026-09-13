# Rust Language Checklist

Add the items below to the shared stage checklists.

---

## Stage 2 — Security

- Is `rand::random()` / `rand::thread_rng()` used for security-relevant randomness? (Prefer
  `rand::rngs::OsRng` or `getrandom`.)
- Does an `unsafe` block dereference a pointer without checking its validity?
- Is external data used unchecked across an FFI boundary?
- Does `serde` deserialization run with no bound on input size?

---

## Stage 3 — Resource management

**Memory**
- Can `Rc<RefCell<T>>` form a reference cycle (is `Weak` used where it should be)?
- Does an `Arc<T>` refcount stay alive longer than expected and hold memory?
- Is memory leaked deliberately with `Box::leak()` documented as such?

**Files & I/O**
- Does the code rely on RAII (`Drop`) to close `File`, `BufReader`, `BufWriter` — and is an
  explicit `flush()` missing?
- Can data be lost because a `BufWriter` is not flushed before it is dropped?

**Async (tokio / async-std)**
- Is a `JoinHandle` dropped without being awaited, discarding its result and any panic?

---

## Stage 4 — Concurrency & performance

**Races**
- When `Send` / `Sync` is implemented by hand in `unsafe` code, is the safety argument stated?
- Is `RefCell<T>` used across threads where `Mutex<T>` belongs?

**Deadlock**
- Is `Mutex::lock()` nested so the same thread locks twice (no reentrancy)?
- Are several `Mutex`es always acquired in the same order?
- Does the code take an `RwLock` write lock while holding a read lock?

**Async (tokio)**
- Does a `tokio::spawn`ed task call a blocking function such as `std::thread::sleep()`? (Use
  `tokio::time::sleep`.)
- Is CPU-bound work run in an async task without `tokio::task::spawn_blocking()`?
- Does `tokio::select!` use a future that is not cancel-safe?

**Performance**
- Are `String`s built in a loop with `+` or repeated `push_str` (consider
  `String::with_capacity`)?
- Is `clone()` called needlessly on a hot path?
- Is `Vec` pre-allocated with `with_capacity` when pushing a large amount of data?
- Does an iterator chain build a needless intermediate collection (`.collect()`)?
