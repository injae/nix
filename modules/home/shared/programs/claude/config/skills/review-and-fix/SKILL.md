---
name: review-and-fix
description: >
  Interactive workflow that walks through review findings one issue at a time and fixes them.
  Takes a /review result, shows each issue in an Emacs buffer in CRITICAL → HIGH → MEDIUM order,
  and after the user confirms, applies the fix, verifies the build and tests, and commits.
triggers:
  - "수정해줘"
  - "리뷰하고 수정해줘"
  - "리뷰 결과 수정해줘"
  - "이슈 하나씩 수정해줘"
  - "review and fix"
  - "fix issues"
user-invocable: true
version: 1.0.0
---

# Review-and-Fix Skill

An interactive workflow that explains and fixes issues one at a time, based on a `/review`
result. Every issue needs the user's confirmation or decision.

The user is addressed in Korean, as the global instructions require; the templates below give the
shape, not the language.

---

## Prerequisite

`/emacs-dev` must have run first. It loads the `mcp__emacs-tools__*` tools, so `goto-line` has to
be available.

---

## Workflow

## Step 1 — Collect the issues

- Use the `/review` result already in the conversation.
- If there is none, run `/review` first.
- Sort by severity: `CRITICAL → HIGH → MEDIUM → LOW`.

---

## Step 2 — Build the queue

Turn the list into an internal queue and repeat Step 3 for each issue.

---

## Step 3 — The issue loop (one issue per confirmation)

Handle every issue in this order.

### Step 3-1 (Emacs mode) — Navigate

Call `goto-line`:

```text
file_path: /absolute/path/file.go
line: first line of the offending code (1-based)
```

Find the code window, open the file, and place the target line near the top (the fifth line).

### Step 3-2 — Explain the issue

Use this shape:

```text
## [SEVERITY] ID: title
📍 file: `path/file.go:line`

### Problem
One sentence on what is wrong.

### Path to the bug
Walk the execution path with quoted code lines.
e.g. "1. A() is called → 2. writes to channel B → 3. blocks forever when no receiver exists"

### Direction of the fix
What changes, and why.

### diff preview
```diff
- old code
+ new code
```

Proceed: **'응 진행해줘'** / Skip: **'스킵'**
```

### Step 3-3 — Wait for the user

Do nothing else until they answer.

- Yes (`응 진행해줘`) → apply the fix
- Skip, no, or a discussion → note the reason and move to the next issue

### Step 3-4 — Apply the fix

Edit the code with the `Edit` tool.

### Step 3-5 — Verify build and tests

Per language, in order:
- Go: `go build ./...` → `go test ./...`
- TypeScript: `tsc --noEmit` → `npm test` (or the project's test command)
- Python: `python -m py_compile` → `pytest`

On failure, diagnose and fix at once. Move on only when everything passes.

---

## Step 4 (Emacs mode) — Group into logical commits

Do this when related fixes have piled up, or when the user asks for a commit.

1. Stage the files — call `git-stage` once per file (pass `file_path`).
2. Prepare the commit buffer — call `git-prepare-commit`:
   - `message`: `fix(package): summary of the change`
   - It only opens the buffer and fills the message in. It does not commit.
3. Stop here and tell the user:
   > "Check the commit message and commit with `C-c C-c`. Tell me when it is done."
4. Wait for their signal.

---

## What a good issue explanation contains

- **The execution path, always**: which condition along A → B → C produces the problem.
- **Quoted code**: the relevant line numbers plus the snippet.
- **Blast radius**: when and under what conditions it actually fires.
- **Behavior after the fix**: why the change resolves it.
- The user has asked for fuller explanations before: give enough context every time.

---

## Skips and pushback

When the user skips an issue or calls it intended behavior:

- A plain skip: note the reason and move on.
- Intended behavior that leaves a real defect (a goroutine leak, a possible deadlock, a resource
  never released):
  1. State the condition and the impact once more and ask again.
  2. If they still want it kept, add a comment recording the intent:

     ```go
     // NOTE: <the defect> — <why it is intended, or the design decision>
     ```

  3. Move to the next issue. Do not raise a skipped issue again.

---

## Step 5 — After the last issue

- If uncommitted files remain, offer to commit.
- Once committed, report a summary of what was fixed and what was skipped.
