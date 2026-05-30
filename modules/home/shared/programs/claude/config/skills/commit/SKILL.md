---
name: commit
description: "Generate a one-line conventional commit message from staged changes, copy it to Emacs clipboard, and open a prefilled Magit commit buffer."
user-invocable: true
allowed-tools:
  - Bash(git diff --cached*)
  - Bash(git log*)
  - mcp__ide__executeCode
  - mcp__emacs-tools__git-prepare-commit
---

# Commit Message Flow

Generate one-line conventional commit text from staged changes. Copy to clipboard. Open Magit commit buffer prefilled.

---

## Step 1 — Gather staged changes

Run in parallel:
- `git diff --cached --stat` — overview of staged files
- `git diff --cached` — full diff content
- `git log --oneline -5` — recent commit style to match

---

## Step 2 — Gate: staged changes exist?

Answer YES/NO:
- **YES** if `git diff --cached --stat` returned file changes
- **NO** if output is empty

If NO, report no staged changes and stop.

---

## Step 3 — Draft commit message

Analyze diff, write one-line message:
- Format: `type(scope): message` ([Conventional Commits](https://www.conventionalcommits.org/))
- Types: `feat`, `fix`, `refactor`, `docs`, `chore`, `style`, `test`
- Scope: affected module/area (`emacs`, `darwin`, `claude`, `home`, etc.)
- One line, English, lowercase, no trailing period

---

## Step 4 — Clipboard + Magit buffer

Run in parallel:
- `executeCode` — `(kill-new "<the commit message>")`
- `git-prepare-commit` — with the message pre-filled

Tell user: press **C-c C-c** to commit.
