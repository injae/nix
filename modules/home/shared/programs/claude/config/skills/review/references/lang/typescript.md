# TypeScript / JavaScript Language Checklist

Add the items below to the shared stage checklists.

---

## Stage 2 — Security

- Is `Math.random()` used for security-relevant randomness? (Use `crypto.getRandomValues()` or
  `crypto.randomUUID()`.)
- Is untrusted external data parsed with `JSON.parse()` and no error handling?
- Is unescaped user input written into `innerHTML` / `outerHTML` (XSS)?
- Does an unvalidated value reach `dangerouslySetInnerHTML`?
- Does external input reach `eval()` or `new Function()`?

---

## Stage 3 — Resource management

**Memory**
- Are listeners added with `addEventListener` removed when the component or object goes away
  (`removeEventListener` or `AbortController`)?
- Does a closure keep a DOM node or a large object alive unintentionally?
- Are `setInterval` / `setTimeout` cleared with `clearInterval` / `clearTimeout` once no longer
  needed?

**Files & I/O (Node.js)**
- Are `fs.createReadStream()` / `fs.createWriteStream()` closed when an error fires?
- Does every stream have an `error` event handler?

---

## Stage 4 — Concurrency & performance

**Races (async)**
- Can shared state change between two `await`s (a TOCTOU pattern)?
- Do tasks running in parallel under `Promise.all()` mutate the same state?

**Async patterns**
- Is a `Promise` rejection left unhandled by `.catch()` or `try/catch`?
- Does an error escape an `async/await` function with no `try/catch`?
- Is work serialized with sequential `await`s where `Promise.all()` would do?
- Does CPU-bound work (crypto, image processing) block the main thread? (Use a Web Worker or
  `worker_threads`.)
- Is an `async` function called from a synchronous context without `await`, so the returned
  promise is dropped?

**Performance**
- Are strings concatenated with `+` in a loop (prefer a template literal or `Array.join`)?
- Is `new RegExp()` constructed on every iteration?
- For a large array, was `for...of` considered instead of `Array.prototype.forEach`?
- Does a React component create a new object or function on every render and cause needless
  re-renders (`useMemo`, `useCallback`)?
