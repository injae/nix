---
name: direnv
description: "Use when `.envrc` exists in cwd. Run one status check, auto-reload only when status indicates miss/stale/unloaded, then use plain shell commands."
user-invocable: true
---

# Direnv Policy

direnv is an environment loader. It is not tied to flake itself.
Use it only to load/update shell environment.

## Workflow

1. At task start, run `direnv status` once.
2. If status indicates miss/stale/unloaded state, run `direnv reload` once automatically.
3. After that, run plain shell commands.
4. If an env-related issue occurs later, run `direnv reload` and retry.

## Notes

- Re-check/reload only after env context changes (`.envrc`, shell reset, toolchain change) or clear env-related failures.
