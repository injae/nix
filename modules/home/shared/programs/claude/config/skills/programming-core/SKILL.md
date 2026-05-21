---
name: programming-core
description: "Apply language-agnostic principles whenever writing, reviewing, or refactoring code in any language. Automatically triggered alongside language-specific skills such as go-development, python-development, typescript-development, and emacs-lisp-development. Covers principles that are independent of language: naming, abstraction, testing, dependencies, and more."
---

# Programming Core Skill

## Common Principles

- Before starting any task, first inspect the relevant files and project structure
- Follow the existing code style and conventions of the project
- After making changes, verify tests, linting, and type checks pass
- Start with small, safe modifications and minimize unnecessary refactoring
- New code must always include error handling and boundary conditions

## Language-Specific Skill Links

- **Go**: use the `go-development` skill
  - Error handling, concurrency, interface patterns
  - Key linters: `golangci-lint`, `go vet`

- **Python**: use the `python-development` skill
  - PEP 8/20 based, type hints, anti-pattern avoidance
  - Key linters: `ruff`, `ty`

- **TypeScript**: use the `typescript-development` skill
  - Strict type safety, anti-pattern avoidance
  - Key linters: `tsc --noEmit`, `eslint`

- **Emacs Lisp**: use the `emacs-lisp-development` skill
  - GNU coding conventions, lexical-binding, package conventions
  - Key linters: `checkdoc`, `package-lint`, `flymake-package`

## Common Code Review Checks

- Do not change logic without tests
- Check for duplicate code (DRY principle)
- Verify that function/variable names reveal their intent
- Extract hardcoded values into constants or configuration
- Ensure security-sensitive data (secrets, passwords) is not present in code