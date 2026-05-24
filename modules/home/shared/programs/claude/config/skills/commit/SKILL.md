---
name: commit-msg
description: "Generate a conventional commit message for staged changes and copy it to the Emacs clipboard. Use when the user asks for a commit message or wants to commit staged files."
user-invocable: true
allowed-tools:
  - Bash(git diff*)
  - Bash(git log*)
  - mcp__emacs-tools__call-fn
  - mcp__emacs-tools__git-prepare-commit
---

# Generate Commit Message

Generate a one-line conventional commit message for staged changes, copy to the Emacs clipboard, and open the Magit commit buffer.

---

## Step 1 — Gather staged changes

Run in parallel:
- `git diff --cached --stat` — overview of what's staged
- `git diff --cached` — full diff content
- `git log --oneline -5` — recent commit style to match

---

## Step 2 — Evaluate: Is there anything staged?

Answer YES or NO:
- **YES** if `git diff --cached --stat` returned file changes
- **NO** if the output is empty

Commit out loud before proceeding:
> "Staged changes: **[present / none]**. Next: **[generate message / inform user]**."

---

## Step 2 (staged = NO) — Nothing to commit

Tell the user nothing is staged and stop.

---

## Step 3 (staged = YES) — Generate commit message

Analyze the diff and write a one-line message:
- Format: `type(scope): message` ([Conventional Commits](https://www.conventionalcommits.org/))
- Types: `feat`, `fix`, `refactor`, `docs`, `chore`, `style`, `test`
- Scope: affected module or area (`emacs`, `darwin`, `claude`, `home`, etc.)
- Message: concise, imperative, lowercase, no trailing period
- One line only — always in English

---

## Step 4 — Copy to Emacs clipboard

Call `call-fn`:
- `name`: `kill-new`
- `args`: `["<the commit message>"]`

---

## Step 5 — Open Magit commit buffer

Call `git-prepare-commit` with the message.

Answer YES or NO — did it succeed?
- **YES** → tell the user to press **C-c C-c** to commit
- **NO** (error: "COMMIT_EDITMSG not found") → Step 5b

---

## Step 5b (prepare-commit = NO) — Open Magit status first

Call `call-fn`:
- `name`: `magit-status`
- `args`: `[]`

Then retry `git-prepare-commit`. Tell the user to press **C-c C-c** to commit.