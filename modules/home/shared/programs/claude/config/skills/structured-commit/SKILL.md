---
name: structured-commit
description: "Split current changes into logical commit units and commit each unit manually via Magit. Use for structured/multi-commit workflows."
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

Analyze all current changes, group into logical commit units, commit each unit in order via Magit.

---

## Step 1 — Gather changes

Run in parallel:
- `git status --short` — staged/unstaged files
- `git diff HEAD` — full diff
- `git log --oneline -5` — recent commit style

---

## Step 1b — Reset staging index

If any file has non-blank first column in `git status --short` (already staged), run:

```bash
git restore --staged .
```

Goal: clean index before per-group staging. Worktree untouched.

---

## Step 2 — Gate: changes exist?

Answer YES/NO:
- **YES** if `git status --short` has file changes
- **NO** if empty

If NO, report no changes and stop.

---

## Step 3 — Propose commit groups

Analyze diff. Split into logical groups.

**Grouping rules:**
- Same feature/fix/module => same group
- Each group must be independently reviewable/revertable
- Multi-file same-purpose changes stay together

**Output format:**
```text
Group 1: feat(claude): add structured-commit skill
  - modules/home/shared/programs/claude/config/skills/structured-commit/SKILL.md

Group 2: fix(emacs): update navigation tool fallbacks
  - modules/home/shared/programs/emacs/config/module/+nav.el
  - modules/home/shared/programs/emacs/config/module/+lsp.el
```

Ask user: "Commit in this order? Let me know if you'd like to adjust."

---

## Step 4 — Gate: user approved?

Answer YES/NO:
- **YES** if user approves/proceeds
- **NO** if user requests changes

If NO, apply feedback, rebuild groups, return Step 3.

---

## Step 5 — Commit groups sequentially

Process groups in order. Wait for user to finish each Magit commit before next group.

For each group:

1. Stage only that group's files in one `git add` call:
   ```bash
   git add <file1> <file2> ...
   ```

2. Follow commit skill Steps 3–4: generate message from group diff, run `kill-new` + `git-prepare-commit` in parallel.

3. Tell user:
   ```text
   [Group N/M] <commit message>
   Press C-c C-c in Magit to commit, then continue here.
   ```

4. After user response, continue next group.

---

## Step 6 — Done

- Print summary of committed groups
- Open Magit status: `call-fn` — `name`: `magit-status`, `args`: `[]`
