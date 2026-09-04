---
name: programming-core
description: "MANDATORY for ANY code writing, editing, reviewing, or refactoring task — regardless of language. Load this skill first, before any language-specific skill (go-development, typescript-development, python-development, etc.). Never skip even if another skill seems sufficient."
---

# Programming Core Skill

## Common Principles
- Start by inspecting relevant files + directory tree.
- Follow existing project style/conventions.
- After changes: tests + lint + typecheck must pass.
- Prefer small safe changes; avoid drive-by refactor.
- Include error handling + boundary conditions in new code.

## Comments
Comment = code that cannot be guaranteed. Never executes, no test covers it, nothing
enforces it still matches the code. Most unstable thing in the file; goes stale by default.

- Default: no comment. Content, names, definitions, usage tracing carry meaning.
- Comment only what those four cannot express: why this over an obvious alternative, or library behavior that contradicts intuition.
- Never restate what code does or what a name says. Adds nothing, rots immediately.
- Long comment = defect report on the code under it. Fix the code, not the prose.
- Exception: heavily optimized or mathematical code (bit tricks, numerical stability, derived formula, hot-path rewrite). Unreadable by design; naming and structure cannot fix it. Comment warranted, still shortest possible. Point to invariant, derivation, or source (paper, formula); do not re-explain.
- Docstring: same rule. Omit unless the reason the function exists is non-obvious.
- Test docstring: omit when the test name explains it. Keep only when the reason the test exists is non-obvious.

## Functional Design
- Write logic as plain functions first.
- Promote to methods only if ownership by a specific type is clear.
- Keep standalone functions standalone when ownership is unclear.
- Prefer immutable data.
- Make data flow explicit via params/returns.
- Remove hidden side effects.
- If mutation is required, push mutation to outermost layer.

## Type Safety
- Treat types as spec.
- Encode absence/failure/state in types, not convention/docs.
- Avoid weak escapes (`any`, `Object`, `interface{}`) unless unavoidable.
- For multi-state values: use sum types + match/switch.
- Prefer exhaustiveness checks over if-chain fallthrough.

## Function Extraction
Extract when:
- No state needed (pure-function candidate)
- Logic repeats (always extract)
- Block size hides surrounding flow
- Sub-operation has independent meaning (nameable in one sentence)

Goal:
- Function body reads as named steps, not low-level operations.

## Code Flow Direction
- Handle error/precondition first (guard clauses / early returns).
- Keep main path linear + shallow.
- Avoid nesting that forces backtracking.

## Data Grouping
- Group related values into struct/class/record when semantics align.
- Group when parameter list grows long.
- Name by meaning, not by raw contents.

## Generic Design
- Before choosing concrete types at boundaries/signatures, test abstract alternatives.
- Depend on minimum required interface (trait/protocol/interface).
- Introduce concrete types only when abstraction cost exceeds benefit.

## Module Independence
- Place functions by type dependency, not feature label.
- Shared/core type dependencies → shared module.
- Adapter-specific type dependencies → adapter module.
- For adapter/provider patterns, split files into:
  1) request building (internal → external)
  2) response parsing (external → internal)
  3) orchestration (network/state/lifecycle)
- Keep (1)(2) independently readable/testable.

## Directory Structure as Structural Context
- Treat folder hierarchy as architectural signal.
- Directory name is a contract (`adapter/`, `handler/`, `internal/`, `domain/`).
- Greater depth usually means tighter coupling + lower reuse.
- Read path before file: path states file purpose.
- Place new code where responsibility belongs, not where caller lives.
- In unfamiliar codebases, map tree first.

## Common Code Review Checks
- No logic change without tests; add tests first if missing.
- Names must reveal intent.
- Replace hardcoded values with constants/config.
- String literals used as identifiers/keys/messages must be named constants.
- No security-sensitive data (secrets/passwords) in code.
