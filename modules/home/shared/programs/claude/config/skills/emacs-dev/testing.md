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
  - Target: any interface (e.g. `Task`, `GracefulTask`)
  - Verify: step 0 (locate file), step 1 (imenu), step 2/3 (lsp-project-symbols)
  - Check: precision note — compare `lsp-project-symbols` vs `lsp-find-implementation` result counts

- [ ] **Pipeline B — Type structure exploration**
  - Target: any concrete type (e.g. `ManagedTask`, `RetryTask`)
  - Verify: `lsp-find-definition` with correct context file, `file-outline`, `symbol-source`
  - Check: Step 1 tip — does using a file that references the type avoid LSP miss?

- [ ] **Pipeline C — Symbol propagation**
  - Target: a struct field (e.g. `limitTime`, `retryDelay`)
  - Verify: `imenu-list-symbols` → `lsp-find-references` → `symbol-source` per site
  - Check: confirm `lsp-project-symbols` returns only declaration (not usages) — this is the known pitfall

### Individual tools

- [ ] **`lsp-find-definition`** — test with a file that references the symbol vs one that doesn't. Document which files cause a miss.
- [ ] **`lsp-find-references`** — test on a function (not just a struct field). Verify all cross-package call sites appear.
- [ ] **`lsp-find-implementation`** — compare result count vs `lsp-project-symbols(method_name)` to confirm precision difference.
- [ ] **`lsp-find-typeDefinition`** — test on a variable (not an interface type). Verify no buffer switch after the `eglot--lsp-xref-helper` fix.
- [ ] **`xref-find-apropos`** — test as primary (not fallback): use a partial name or pattern. Verify project-local vs external hit ratio.
- [ ] **`lsp-project-symbols` vs `lsp-workspace-symbols`** — run same query on both. Count project vs external hits to confirm noise difference.
- [ ] **`file-outline`** — verify treesit availability field and that symbol list matches `imenu-list-symbols`.
- [ ] **`symbol-source`** — test on a leaf-line number (not a declaration start). Verify tree-sitter finds the enclosing declaration.
- [ ] **`treesit-info`** — land on a keyword token (e.g. `func`). Verify leaf node returned, then `include_ancestors: true` gives `method_declaration`.
- [ ] **`goto-file-line`** — verify it opens in the user's code window (not the claude-code buffer) and scrolls to the target line.
- [ ] **`getDiagnostics`** — run after introducing a deliberate type error. Verify the error appears in output.

---

## Known tool behaviors (from validation history)

| Tool | Observed behavior | Implication |
|------|------------------|-------------|
| `lsp-find-definition` | Miss if `file_path` doesn't reference the symbol | Always pass a file that imports or uses the target |
| `lsp-project-symbols(name)` | Returns declarations only, not usages | Use `lsp-find-references` for usage tracking (Pipeline C) |
| `lsp-find-typeDefinition` | gopls returns nothing for interface types | Fall back to `lsp-find-definition(identifier)` |
| `lsp-find-typeDefinition` | Was using `eglot--lsp-xref-helper` → buffer switch (fixed 2026-05-22) | Use direct `eglot--request` for all position-based tools |
| `lsp-workspace-symbols(name)` | Returns 100 results including `/nix/store/`, `/go/pkg/mod/` | Prefer `lsp-project-symbols` for project-only searches |
| `treesit-info` on keyword | Returns leaf node (`func`, `type`) | Retry with `include_ancestors: true` to get declaration node |
| `describe-symbol` | Emacs Lisp symbols only — Go symbols not found | See `elisp.md` |