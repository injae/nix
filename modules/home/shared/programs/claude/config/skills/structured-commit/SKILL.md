---
name: structured-commit
description: "Analyze current changes, divide into logical commit units, and commit each unit manually via Magit. Use when the user wants to split changes into multiple organized commits, or asks for 'structured commit', 'multi-commit', or 'commit by unit'."
user-invocable: true
allowed-tools:
  - Bash(git diff*)
  - Bash(git log*)
  - Bash(git status*)
  - Bash(git add*)
  - mcp__emacs-tools__call-fn
  - mcp__emacs-tools__git-prepare-commit
---

# Structured Commit

Analyze all current changes, group them into logical commit units, and commit each unit sequentially via Magit.

---

## Step 1 — Gather changes

Run in parallel:
- `git status --short` — staged/unstaged file list
- `git diff HEAD` — full diff content
- `git log --oneline -5` — recent commit style to match

---

## Step 1b — Reset staging index

If **any** files show a non-blank first column in `git status --short` (i.e., already staged), run:

```
git restore --staged .
```

This gives a clean index before group-by-group staging. Worktree files are untouched.

---

## Step 2 — Evaluate: Are there changes?

Answer YES or NO:
- **YES** if `git status --short` returned file changes
- **NO** if the output is empty

If NO → tell the user there are no changes and stop.

---

## Step 3 — Propose commit groups

Analyze the diff and divide changes into logical groups.

**Grouping criteria:**
- Files belonging to the same feature, fix, or module go in the same group
- Each group should be independently reviewable and revertable
- Changes spanning multiple files for the same purpose stay together

**Output format:**
```
Group 1: feat(claude): add structured-commit skill
  - modules/home/shared/programs/claude/config/skills/structured-commit/SKILL.md

Group 2: fix(emacs): update navigation tool fallbacks
  - modules/home/shared/programs/emacs/config/module/+nav.el
  - modules/home/shared/programs/emacs/config/module/+lsp.el
```

Ask the user: "Commit in this order? Let me know if you'd like to adjust."

---

## Step 4 — Evaluate: User approved?

Answer YES or NO:
- **YES** if the user approves or signals to proceed
- **NO** if the user requests changes

If NO → incorporate feedback, rebuild groups, return to Step 3.

---

## Step 5 — Commit each group sequentially

Process groups in order. Wait for the user to complete each Magit commit before proceeding to the next.

**For each group:**

1. Stage only that group's files in a single `git add` call:
   ```
   git add <file1> <file2> ...
   ```

2. Follow **commit Steps 3–4**: generate the commit message for this group's diff, then run `kill-new` + `git-prepare-commit` in parallel.

3. Tell the user:
   ```
   [Group N/M] <commit message>
   Press C-c C-c in Magit to commit, then continue here.
   ```

4. When the user responds → proceed to the next group.

---

## Step 6 — Done

- Print a summary of all committed groups
- Open Magit status: `call-fn` — `name`: `magit-status`, `args`: `[]`