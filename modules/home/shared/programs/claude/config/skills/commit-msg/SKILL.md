---
name: commit-msg
description: "Generate a conventional commit message for staged changes and copy it to the Emacs clipboard. Use when the user asks for a commit message or wants to commit staged files."
user-invocable: true
allowed-tools:
  - Bash(git diff*)
  - Bash(git log*)
  - mcp__emacs-tools__claude-code-ide-mcp-call-function
---

# Generate Commit Message

Generate a one-line conventional commit message for staged changes and copy it to the Emacs clipboard.

## Steps

1. Run in parallel via Bash:
   - `git diff --cached --stat`
   - `git diff --cached`
   - `git log --oneline -5` — to match the repo's commit message style

2. Analyze the staged diff and generate a commit message:
   - Follow [Conventional Commits](https://www.conventionalcommits.org/): `type(scope): message`
   - Common types: `feat`, `fix`, `refactor`, `docs`, `chore`, `style`, `test`
   - Scope: the affected module or area (e.g. `emacs`, `darwin`, `claude`, `home`)
   - Message: concise, imperative, lowercase, no trailing period
   - One line only

3. Copy the message to the Emacs clipboard via `call-function`:
   - function: `kill-new`
   - args_json: `["<commit message>"]`

4. Show the message to the user.
