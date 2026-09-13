# Python Language Checklist

Add the items below to the shared stage checklists.

---

## Stage 2 — Security

- Is `random.random()` / `random.randint()` used for security-relevant randomness? (Use the
  `secrets` module.)
- Is untrusted data passed to `pickle.loads()` (arbitrary code execution)?
- Is `yaml.safe_load()` used rather than `yaml.load()`?
- Does external input reach `eval()` or `exec()`?
- Is unvalidated input passed to `subprocess` with `shell=True`?

---

## Stage 3 — Resource management

**Memory**
- Can a reference cycle form (is `weakref` used where it should be)?
- Does any cleanup depend on `__del__` (the GC gives no guarantee)?
- Is a large dataset materialized with `list()` where a generator or iterator would do?

**Files & I/O**
- Is the `with open(...)` context manager used?
- Is a file opened inside a loop and left open when an exception fires?

**Database**
- Is the cursor closed with `close()` or a context manager?
- Is the connection returned in a `finally` block or by a context manager?

---

## Stage 4 — Concurrency & performance

**Races**
- Is there an operation the GIL does not protect?
  - Shared state under `multiprocessing` accessed without `Manager`, `Value`, or `Array`
  - Shared state mutated across an `await` in `asyncio`

**Async patterns (asyncio)**
- Is CPU-bound work run directly inside an `async def`, blocking the event loop? (Use
  `loop.run_in_executor` or `asyncio.to_thread`.)
- Are exceptions from tasks inside `asyncio.gather()` handled?
- Is a task from `asyncio.create_task()` kept referenced, so the GC cannot cancel it?
- Is an async function called from a synchronous context without `await`?

**Performance**
- Are strings concatenated with `+` in a loop (use `"".join()`)?
- Is `re.match()` / `re.search()` called in a loop without `re.compile()`?
- Is a needless intermediate list built where a comprehension would do?
