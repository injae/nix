# Sequential Workflow Style

Use this style when the skill describes an ordered sequence of steps with decision points,
tool selection, or conditional branching. The goal is to make execution unambiguous:
the model should never have to guess what to do next.

---

## Step header format

```markdown
## Step N — Short description of what happens in this step
## Step N (condition = VALUE) — Title used when a step only applies under a condition
```

Use an em dash (`—`), not a colon or hyphen.

---

## Decision point + commit-out-loud

When a step requires the model to evaluate something and choose a path,
force an explicit decision before proceeding. This prevents silent wrong turns.

```markdown
## Step 1 — Evaluate: Is X available?

Call `some-tool(file_path)` to check.

Answer YES or NO:
- **YES** if condition A
- **NO** otherwise

Commit out loud before proceeding:
> "X is **[available / not available]** for `[target]`. Next tool: **[tool-name]**."
```

The "commit out loud" quote is a signal to the reader and a forcing function for the model —
it must state its decision in the response before calling the next tool.

---

## Conditional step headers

When a step only applies under a specific condition, annotate the header:

```markdown
## Step 2 (tree-sitter = YES) — Get the symbol source
## Step 2 (tree-sitter = NO) — Fall back to Read
```

This makes the branching structure visible at a glance without needing to read the body.

---

## Tool selection table

When multiple tools exist for the same class of task, a table communicates the decision
matrix more clearly than prose:

```markdown
| Task | Tool | Fallback |
|------|------|----------|
| Find definition | `lsp-def` | `xref-apropos` |
| Search symbols | `lsp-ws-symbols` | `xref-apropos` |
| Read declaration | `symbol-source` | `Read` with offset/limit |
```

---

## Gate check

A gate check is a checklist placed before an expensive or irreversible action.
It prevents the model from skipping earlier steps and jumping straight to the action.

```markdown
**Gate check — before calling `Read`, confirm:**
1. `file-outline` was called for this file → structure obtained
2. If tree-sitter available: `symbol-source` was called → result was insufficient
3. Only then: `Read` is justified

If you cannot confirm steps 1–2, go back and complete them first.
```

---

## Horizontal rules between steps

Separate each step with `---`. This makes the step boundaries visually unambiguous
when the skill body is long.

---

## Complete example

```markdown
## Step 1 — Evaluate: Is tree-sitter available?

Call `file-outline(file_path)`. Returns major-mode, treesit status, and symbol list.

Answer YES or NO:
- **YES** if `treesit: available`
- **NO** otherwise

Commit out loud before proceeding:
> "Tree-sitter is **[available / not available]** for `[file]`. Next tool: **[symbol-source / Read]**."

---

## Step 2 (tree-sitter = YES) — Identify the target symbol

The symbol list from Step 1 contains line numbers. Identify the target and its line.

Commit out loud before proceeding:
> "Target `[symbol]` is at line [N]. Next tool: **symbol-source** at line [N]."

---

## Step 3 (tree-sitter = YES) — Get source

Call `symbol-source(file_path, line)`.

Answer YES or NO — is the result complete and correct?
- **YES** → done.
- **NO** → commit out loud: "symbol-source insufficient. Falling back to **Read** at lines [start–end]."

---

## Step 4 — Read (only if Step 3 = NO, or tree-sitter unavailable)

Call `Read` with a specific line range.

**Gate check — before calling `Read`, confirm:**
1. `file-outline` was called → structure obtained
2. `symbol-source` was called (if tree-sitter available) → result was insufficient
```