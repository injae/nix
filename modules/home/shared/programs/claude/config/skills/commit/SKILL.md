---
name: commit
description: "Generate a conventional commit message for already-staged changes and open the Magit commit buffer with it pre-filled. Use when the user asks for a commit message or wants to commit already-staged files."
user-invocable: true
allowed-tools:
  - Bash(git diff --cached*)
  - Bash(git log*)
  - mcp__emacs-tools__call-fn
  - mcp__emacs-tools__git-prepare-commit
---

# Generate Commit Message

Generate a one-line conventional commit message from staged changes, copy it to the Emacs clipboard, and open the Magit commit buffer with it pre-filled.

---

## Step 1 — Gather staged changes

Run in parallel:
- `git diff --cached --stat` — overview of staged files
- `git diff --cached` — full diff content
- `git log --oneline -5` — recent commit style to match

---

## Step 2 — Evaluate: Is there anything staged?

Answer YES or NO:
- **YES** if `git diff --cached --stat` returned file changes
- **NO** if the output is empty

If NO → tell the user nothing is staged and stop.

---

## Step 3 — Generate commit message

Analyze the diff and write a one-line message:
- Format: `type(scope): message` ([Conventional Commits](https://www.conventionalcommits.org/))
- Types: `feat`, `fix`, `refactor`, `docs`, `chore`, `style`, `test`
- Scope: affected module or area (`emacs`, `darwin`, `claude`, `home`, etc.)
- One line, English, lowercase, no trailing period

---

## Step 4 — Copy to clipboard and open Magit commit buffer

Run in parallel:
- `call-fn` — `name`: `kill-new`, `args`: `["<the commit message>"]`
- `git-prepare-commit` — with the message pre-filled

Tell the user to press **C-c C-c** to commit.