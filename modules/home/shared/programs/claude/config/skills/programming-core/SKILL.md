---
name: programming-core
description: "Apply language-agnostic principles whenever writing, reviewing, or refactoring code in any language. Automatically triggered alongside language-specific skills such as go-development, python-development, typescript-development, and emacs-lisp-development. Covers principles that are independent of language: naming, abstraction, testing, dependencies, and more."
---

# Programming Core Skill

## Common Principles

- Before starting any task, inspect the relevant files and directory structure first
- Follow the existing code style and conventions of the project
- After making changes, verify tests, linting, and type checks pass
- Start with small, safe modifications and minimize unnecessary refactoring
- New code must always include error handling and boundary conditions

## Language-Specific Skill Links

| Language | Skill |
|----------|-------|
| Go | `go-development` |
| Python | `python-development` |
| TypeScript | `typescript-development` |
| Emacs Lisp | `emacs-lisp-development` |

## Functional Design

Write logic as a plain function first; promote it to a method only when it naturally belongs to a specific type. Functions that don't clearly belong to any type stay standalone. Prefer immutable data, make data flow explicit through arguments and return values, and eliminate hidden side effects. When mutation is unavoidable, push it to the outermost layer.

## Type Safety

The type system is the specification — encode absence, failure, and distinct states directly in types rather than relying on convention or documentation. Avoid weakly-typed escape hatches (`any`, `Object`, `interface{}`) unless the abstraction genuinely has no type. When a value can be one of several distinct states, use a sum type and prefer match/switch over if-chains: exhaustiveness checking turns forgotten cases into compile errors.

## Function Extraction

Extract inline logic into named functions when:
- It needs no state (pure function criterion)
- The same logic appears more than once — always extract
- A code block is large enough to obscure the surrounding flow
- A sub-operation has independent meaning (nameable in one sentence)

The goal: each function body reads like a list of named steps, not a sequence of low-level operations.

## Code Flow Direction

Write code so the direction of execution is obvious at a glance. Handle error cases and preconditions first with guard clauses or early returns, keeping the main path linear and unindented. Avoid nesting that forces the reader to backtrack.

## Data Grouping

When related values can be logically grouped — or when a parameter list grows too long — define a struct (or class/record) for them. The name should express what the group *means*, not just what it contains.

## Generic Design

Before committing to a concrete type in a signature, data structure, or module boundary, ask whether a more abstract form works just as well. Depend on the minimum interface required (trait, protocol, interface) rather than a specific type. A concrete type is a constraint; introduce it only when the abstraction costs more than it saves.

## Module Independence

Where a function lives is determined by what types it depends on, not what feature it belongs to. Functions that only use shared/core types belong in a shared module; functions that depend on adapter-specific types belong in the adapter module.

For adapter/provider patterns, separate into three files: **request building** (internal → external types), **response parsing** (external → internal types), and **orchestration** (network, state, lifecycle). This lets the first two be read and tested independently.

## Directory Structure as Structural Context

The folder hierarchy encodes architectural intent — read it as a first-class signal before touching any file.

- **Directory name** is a contract: `adapter/`, `handler/`, `internal/`, `domain/` constrain what lives inside
- **Depth** signals coupling: deeper files are more specific and less reusable
- **Before reading a file, read its path** — it tells you what the file is *for* before you see any code
- **When placing new code**, choose the directory whose name matches the responsibility, not where the caller lives
- **When exploring unfamiliar code**, map the directory tree first — the shape reveals the architecture faster than any single file

## Common Code Review Checks

- Do not change logic without tests; if tests are missing, add them first
- Verify that function/variable names reveal their intent
- Extract hardcoded values into constants or configuration; string literals used as identifiers, keys, or messages belong in named constants
- Ensure security-sensitive data (secrets, passwords) is not present in code
