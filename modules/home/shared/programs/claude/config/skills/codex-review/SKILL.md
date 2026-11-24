---
name: codex-review
description: Obtain an independent review of a commit, range, uncommitted tree, or implementation plan and report the verdict plus findings. Codex uses an in-session reviewer agent; other executors use the Codex CLI workflow below.
---

# Codex review

## Entry by executor

**Executor is Codex: run as independent reviewer agent in current session.** CLI path only when user explicitly asks for CLI. No workaround of having another agent run CLI command.

Codex path: hand reviewer agent (not implementer, not plan author) paths to review target, rule/structure docs, plan, evidence, existing check results, previous reviews and rebuttals. Keep scope pinning, direct code evidence, per-round files, report contract below. Reviewer agent edits no file, reruns no existing check; reads real code + existing check evidence, returns verdict + findings by severity + exact `file:line`, in Korean. Caller saves returned review to round file, reports in Step 4 shape. No agent or agent fails: report limit, no auto switch to CLI. **Codex path ends here — no CLI or fallback steps below.**

Claude and other executors: CLI path below.

## CLI path

Four tool calls. Nothing else in a round.

Was a subagent. Now skill: agent picks own prep and kept transcribing. Measured 2026-09-12, one round: 24 KB prompt, 281 of ~360 lines transcription — `graph` output turned into prose, two PR bodies, comment ledger pasted, convention files summarized, eight commit subjects copied from `git log`. Same round reached tool removed from its `tools:` line through Bash, and returned `Cross-check: not done` while reporting verified test counts and read source. Procedure leaves no room for that.

## Inputs

- **Review target** — git range (`main..HEAD`), commit SHA, or "uncommitted".
- **Review name** — used in filenames.
- **Check command** — repo build/lint command (e.g. `just check`). **Required.** Without it Codex rediscovers one and runs suite itself (observed: `cargo test jobs::designate::deconstruct --lib`), and under `--approve-for-me` every exec costs extra approval pass. Ask, never guess.
- **Conventions path** — `AGENTS.md` / `CLAUDE.md`, if any.
- **Structure doc path** — `docs/map/<axis>.md`, if any.
- **Self-report path** — `.claude/tmp/*.md` (optional).

Repo needs only `.claude/tmp/`, gitignored work folder.

## Step 1 — Write prompt

Write `.claude/tmp/codex-prompt-<name>-r<n>.md`. **Target 2 KB or less.**

**Every round file carries round number** — prompt, review, log. Never rename previous round's file: measured 2026-09-23, round 1 review moved after round 2 prompt named old path (round 2's own `-o` target); reviewer could not open round it had to judge.

**Paths, never contents.** Codex runs with `-C <repo>` + workspace-write, opens every file with `cat`. Includes `.claude/tmp/`: gitignored so `git show` can't reach it, `cat` can — old "paste, do not link" rule was wrong.

No `graph`, `git log`, `git diff` to build prompt. Name range, Codex runs them.

Fill slots; rest verbatim.

```markdown
Review <target>. Round <n>. Previous round asked for: <one line, or "first round">.

Read target yourself with git:
  git log <range>
  git diff <range>
(commit: `git show <sha>`, files with `git show <sha>:<path>` · uncommitted: `git diff HEAD`
plus `git status --short`)

Open these yourself — paths, not quoted here:
- conventions: <path>   (if repo batches comment approval at end of workstream, stated there —
  do not file "no approval evidence")
- structure map: <path>
- self-report: <path>   (judge whether its rebuttals are correct)
- previous review: .claude/tmp/codex-review-<name>-r<n-1>.md   (round 2+)
`.claude/tmp/` is gitignored: `git show` can't open it, `cat` can.

Run before judging: <check command>

Structure — callers, file API, directory map — from graft index: `graft_trace_calls`
(`depth: "all"` for rename), `graft_file_api`, `graft_repo_map`. `no graph found` or
`no symbol "X" in the graph` = no index or language not parsed: use LSP tools + `grep-block`,
say so. Empty graft output = fact about index, not "there are none".

`graph` answers only "already judged? what left unfollowed?". Pass this repo's path — unnamed
`graph` answers for other project. Report empty answer as `never traced` or `traced, no such
edge`, never as reason to sweep wide. MCP tools read working tree, not reviewed commit:
background only; finding resting on one must say working-tree state may differ from commit.
`trace` writes to that store: call only when relation this review turns on is missing, scope
with `path`, pass `ask` containing this review's name.

Write, create, modify no file. Reply is the review; captured to file for you.

Structure map, three jobs:
1. Read invariants — rules + guarding test. Structure itself not here: ask graft index.
2. Judge whether diff left it stale — new type, seam, invariant missing from map = finding,
   same as missing test.
3. Close every `?` row — confirmed, wrong, or still unreachable. `?` surviving round
   unexamined = finding.

No limit on finding kinds — defects, design deviations, convention violations, missed spots,
dead code, fake safeguards; anything with code evidence. Lists claimed "exhaustive": count and
verify yourself.

Write in **English**, **caveman style**. Drop articles, qualifiers, hedges; facts only.
Fragments fine. One finding = one-line gist + `file:line` + one or two lines evidence. No
restating. Quote code and `file:line` exactly. End with `Verdict: pass | needs changes | unresolved`
and counts `P1 n · P2 n · P3 n`.
```

English line **unreliable** — Codex answered in Korean with it present (2026-09-12). Keep line; English output not guaranteed.

### Field of view — two things

**Finding kinds stay open.** No "look only at these" list: reviewer view shrinks to caller's suspicion, round returns nothing.

**Reading target stays pinned to review range.** Never write scope sentence widening it. Observed 2026-09-12: "Scope: the whole of src/ and tests/. Do not restrict the review to the changed files" turned one-commit review into whole-tree audit.

## Step 2 — Run Codex

**Background job** (`run_in_background: true`), no separate `sleep`. Round takes 2–10 min; foreground blocks conversation whole time. Harness re-invokes you on exit; no polling. Keep working or answer user meanwhile; Step 3 only after completion notification.

```bash
codex exec --approve-for-me -C <repo> --color never \
  -o .claude/tmp/codex-review-<name>-r<n>.md \
  "$(cat .claude/tmp/codex-prompt-<name>-r<n>.md)" < /dev/null \
  > .claude/tmp/codex-run-<name>-r<n>.log 2>&1
```

**`< /dev/null` mandatory.** codex reads extra stdin input when stdin not TTY; harness feeds multi-line Bash through stdin. Without redirect it blocks on "Reading additional input from stdin..." until timeout (observed: 600 s, zero output).

**`--approve-for-me`, not `--sandbox read-only`.** `codex exec` non-interactive, pins approval policy to `never`; every MCP call dies on `MCP tool call requires approval, but approval policy is never`; `-c approval_policy=...` doesn't override (codex-cli 0.154.0). `--approve-for-me` routes approvals through automatic review, raises sandbox to `workspace-write [workdir, /tmp, $TMPDIR]` — sandbox no longer stops reviewer writing, only prompt does; each approved call costs extra model pass.

**Permission classifier refuses it** — auto-mode session can deny `--approve-for-me` as "Create Unsafe Agents" (observed 2026-09-12): fall back to `--sandbox workspace-write`. Loses MCP approval elevation, still produces findings. Say which ran.

**Not `codex exec review`**: its `--commit` can't combine with custom prompt, no `--color` (codex-cli 0.153.2).

## Step 3 — Read result

Read `.claude/tmp/codex-review-<name>-r<n>.md`. Round review ~2 KB.

**Spent usage limit exits 0 with no `-o` file.** Log's last line: `ERROR: You've hit your usage limit … try again at <date>`, exit 0, so exit-code check calls it success. `-o` file missing: `grep -i "usage limit"` run log first. Report retry date; no retry. Such run can sit over an hour (observed 2026-09-05: 73 min, killed by hand) — over 15 min with no `-o` file = failed. Trivial probe (`codex exec --sandbox read-only --color never "say OK"`) still answers on spent quota: trust log line, not probe.

Nonzero exit or empty output file: report failure as is. Retry at most once.

## Step 4 — Report

```
Verdict: <pass | needs changes | unresolved>
Counts: P1 n · P2 n · P3 n
Full text: .claude/tmp/codex-review-<name>-r<n>.md

[P2] <one-line gist> — <file:line>
[P3] <one-line gist> — <file:line>
```

No findings: omit findings lines, report `Verdict: pass`.

**No verifying findings here.** Report what Codex said, its own `file:line`, gist only, not re-derived. Confirming against source = next step of work cycle; doing it inside review pays same read twice. Measured 2026-09-12: round cost 105k tokens over 45 tool calls, mostly re-opening files Codex already read.

Relay verdict as is. Looks false positive: **append** that, never erase reviewer's words.

## Not this

- No source edits here. Applying findings = caller's next step.
- Never `git restore`, `checkout`, `reset`, `stash` — tree may be staged for next task.

## When Codex unavailable

Usage limit hit, CLI missing, run failed: use `fable-review` agent, same review contract on Fable. Say which produced result.
