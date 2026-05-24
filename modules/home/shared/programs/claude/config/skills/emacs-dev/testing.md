# Navigation Skill Validation

Read this file when the user asks to validate, test, or evaluate navigation skills — or when `navigation.md` has been updated and correctness needs to be verified.

## When to run

- After editing `navigation.md` (tool table, pipelines, or rules changed)
- After adding or modifying an MCP tool in `+lsp-navigation.el`
- When a tool produces unexpected output in a real task

---

## Per-scenario format

Run each scenario against real project code. After each one, report in this format before moving to the next:

**Step table** — one row per tool call:

| Step | Tool | Input | Output summary |
|------|------|-------|----------------|
| 1 | `tool-name(args)` | what you passed | what came back (1 line) |

**Evaluation** — two sections:
- *Worked well*: what matched expectations
- *Problems*: failures, false positives, side effects, unnecessary round-trips

**Improvements**: concrete changes to apply to `navigation.md` or the MCP tool source.

Apply improvements immediately after each scenario, before moving on.

---

## Scenario coverage checklist

### Pipelines

- [ ] **Pipeline A — Interface change impact**
  - Target: any interface in the current project
  - Verify: step 0 (locate file), step 1 (`imenu-symbols`), step 2/3 (`lsp-proj-symbols`)
  - Check: precision note — compare `lsp-proj-symbols` vs `lsp-impl` result counts

- [ ] **Pipeline B — Type structure exploration**
  - Target: any concrete type in the current project
  - Verify: `lsp-def` with correct context file, `file-outline`, `symbol-source`
  - Check: Step 1 tip — does using a file that references the type avoid LSP miss?

- [ ] **Pipeline C — Symbol propagation**
  - Target: any struct field in the current project
  - Verify: `imenu-symbols` → `lsp-refs` → `symbol-source` per site
  - Check: confirm `lsp-proj-symbols` returns only declaration (not usages) — this is the known pitfall

### Individual tools

- [ ] **`lsp-def`** — test with a file that references the symbol vs one that doesn't. Document which files cause a miss.
- [ ] **`lsp-refs`** — test on a function (not just a struct field). Verify all cross-package call sites appear.
- [ ] **`lsp-impl`** — compare result count vs `lsp-proj-symbols(method_name)` to confirm precision difference.
- [ ] **`lsp-type-def`** — test on a variable (not an interface type). Verify no buffer switch after the `eglot--lsp-xref-helper` fix.
- [ ] **`xref-apropos`** — test as primary (not fallback): use a partial name or pattern. Verify project-local vs external hit ratio.
- [ ] **`lsp-proj-symbols` vs `lsp-ws-symbols`** — run same query on both. Count project vs external hits to confirm noise difference.
- [ ] **`file-outline`** — verify treesit availability field and that symbol list matches `imenu-symbols`.
- [ ] **`symbol-source`** — test on a leaf-line number (not a declaration start). Verify tree-sitter finds the enclosing declaration.
- [ ] **`treesit-info`** — land on a keyword token (e.g. `func`). Verify leaf node returned, then `include_ancestors: true` gives `method_declaration`.
- [ ] **`goto-line`** — verify it opens in the user's code window (not the claude-code buffer) and scrolls to the target line.
- [ ] **`getDiagnostics`** — run after introducing a deliberate type error. Verify the error appears in output.

---

## Known tool behaviors (from validation history)

| Tool | Observed behavior | Implication |
|------|------------------|-------------|
| `lsp-def` | Miss if `file_path` is not in the same package as the symbol definition — importing the package is not enough | Pass a file from the symbol's own package; use `lsp-proj-symbols` first to find the definition file |
| `xref-apropos` | Includes `/go/pkg/mod/`, `/nix/store/` external hits — same noise level as `lsp-ws-symbols` | Not a noise-free fallback; prefer `lsp-proj-symbols` for project-internal searches |
| `lsp-refs` (function) | Returns cross-package and test-file call sites accurately — grep-verified complete | Reliable for function-level usage tracking across package boundaries |
| `lsp-proj-symbols(name)` | Returns declarations only, not usages | Use `lsp-refs` for usage tracking (Pipeline C) |
| `lsp-type-def` | gopls returns nothing for interface types | Fall back to `lsp-def(identifier)` |
| `lsp-type-def` | Was using `eglot--lsp-xref-helper` → buffer switch (fixed 2026-05-22) | Use direct `eglot--request` for all position-based tools |
| `lsp-ws-symbols(name)` | Returns 100 results including `/nix/store/`, `/go/pkg/mod/` | Prefer `lsp-proj-symbols` for project-only searches |
| `treesit-info` on keyword | Returns leaf node (`func`, `type`) | Retry with `include_ancestors: true` to get declaration node |
| `describe-symbol` | Emacs Lisp symbols only — Go symbols not found | See `elisp.md` |
| `lsp-proj-symbols` with common method name | Returns all types with that method name, not just interface implementors | Use `lsp-impl` for exact implementors; `lsp-proj-symbols` count will be higher |
| `lsp-type-def` at non-variable position | gopls: "no enclosing expression has a type" | Only valid at variable/parameter positions; fall back to `lsp-def` for function names |
| `symbol-source` on `emacs-lisp-mode` file | treesit parser not active → 30-line fallback read | Expected — `emacs-lisp-mode` has no tree-sitter mode; result is still correct |