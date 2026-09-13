---
name: review
description: >
  Sashiko-style multi-stage code review skill.
  Subagents review in order — architecture, security, resources, concurrency —
  and the main agent merges their output into one final report.
triggers:
  - "리뷰"
  - "코드 리뷰"
  - "PR 리뷰"
  - "리뷰해줘"
  - "review this"
  - "코드 검토"
  - "sashiko review"
  - "review"
  - "diff 리뷰"
  - "패치 리뷰"
version: 1.0.0
---

# Sashiko Review Skill

Four-stage multi-agent review, sashiko style. Each stage examines the same code from its own
angle, and the last step stitches them into one report.

---

## When to use

- A code diff or patch is sent for review
- A PR body is reviewed as text
- A file or a function is examined
- Someone asks whether the code has bugs or security problems

---

## Review pipeline

Order is fixed. Each stage takes the previous stage's result as input.

```text
input → Stage 1 (architecture) → Stage 2 (security) → Stage 3 (resources) → Stage 4 (concurrency) → final report
```

---

## Procedure

1. **Identify the input**
   - Confirm the code, diff, or file path.
   - Prefer tree-sitter and LSP/MCP tools over reading whole files.
   - Under Emacs, follow the file-analysis flow of `emacs-dev`.

2. **Detect the language**
   - Go by extension first: `.go` / `.py` / `.ts` `.tsx` `.js` `.jsx` / `.rs`.
   - When the extension is unclear, decide from syntax — imports, keywords, type declarations.

3. **Load the language reference**
   - Read the file when one exists.
   - ${Lang} -> `references/lang/${lang}.md` (e.g. `references/lang/go.md`)
   - Go → `references/lang/go.md`
   - Python → `references/lang/python.md`
   - TypeScript / JavaScript → `references/lang/typescript.md`
   - Rust → `references/lang/rust.md`

4. **Run the stages in order**
   - Each stage applies the shared prompt plus that stage's section of the language file.

5. **Merge the results**
   - The main reviewer prints the final report in the `references/final-report.md` format.

Stage prompt paths:
- Stage 1: `references/01-architecture.md`
- Stage 2: `references/02-security.md`
- Stage 3: `references/03-resource.md`
- Stage 4: `references/04-concurrency.md`
- Final merge: `references/final-report.md`

---

## Severity levels

| Level    | Meaning                                        | Handling                        |
|----------|------------------------------------------------|---------------------------------|
| CRITICAL | Must be fixed now; blocks the merge             | Fix, then review again          |
| HIGH     | Serious bug or vulnerability; fix before merge  | Fix before merging              |
| MEDIUM   | Worth improving; technical debt accumulates     | Track as an issue               |
| LOW      | Style or minor suggestion                       | Apply at the author's discretion|
| INFO     | Observation, including a positive one           | For reference                   |

---

## Principles

- **Evidence first**: every finding carries a code line and its grounds.
- **Language-agnostic**: respect the idioms of Go, Python, TS, and Rust.
- **False positives are acceptable**: a missed bug costs more. Say it when in doubt.
- **YAGNI**: do not propose features that are absent. Review the code as it is.
- **Carry a fix**: CRITICAL and HIGH findings include a fix snippet where one is possible.
