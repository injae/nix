---
name: codex-review
description: Send a commit, range, or uncommitted tree to the Codex CLI for review and report only the verdict plus one line per finding. Use whenever code review of a commit, range, or working tree is wanted. Replaces the former codex-review subagent — Codex does the reviewing, this procedure only forwards.
---

# Codex review

Four tool calls. Nothing else belongs in a round.

This used to be a subagent. It is a skill because an agent decides for itself what preparation to
do, and it kept deciding to transcribe. Measured 2026-09-12, one round: the agent wrote a 24 KB
prompt of which 281 of ~360 lines were transcription — `graph` output expanded into prose, two PR
bodies pasted, the comment ledger pasted, the convention files summarized, eight commit subjects
copied out of `git log`. In the same round it reached a tool that had been removed from its
`tools:` line by calling it through Bash instead, and it returned `Cross-check: not done` while
the same reply reported having verified test counts and read source. A procedure has no room for
that.

## Inputs

- **Review target** — a git range (`main..HEAD`), a commit SHA, or "uncommitted".
- **Review name** — used in the filenames.
- **Check command** — the repo's build/lint command (e.g. `just check`). **Required.** Without it
  Codex rediscovers one and runs the suite itself (observed: `cargo test
  jobs::designate::deconstruct --lib`), and under `--approve-for-me` every exec costs an extra
  approval pass. Ask for it rather than guessing.
- **Conventions path** — `AGENTS.md` / `CLAUDE.md`, if the repo has one.
- **Structure doc path** — `docs/map/<axis>.md`, if the repo has one.
- **Self-report path** — `.claude/tmp/*.md` (optional).

The repo needs only `.claude/tmp/`, a gitignored work folder.

## Step 1 — Write the prompt

Write `.claude/tmp/codex-prompt-<name>-r<n>.md`. **Target 2 KB or less.**

**Every file of a round carries its round number** — prompt, review, log. Never rename a previous
round's file to make room: measured 2026-09-23, round 1's review was moved after round 2's prompt
already named its old path, which was round 2's own `-o` target, so the reviewer could not open the
round it was asked to judge.

**Paths, never contents.** Codex runs with `-C <repo>` and workspace-write; it opens every file
itself with `cat`. That includes anything under `.claude/tmp/`: it is gitignored, so `git show`
cannot reach it, but `cat` can — the old "paste, do not link" rule was wrong about this.

Do not run `graph`, `git log`, or `git diff` to build the prompt. Name the range and let Codex run
them.

Fill the slots; leave the rest verbatim.

```markdown
Review <target>. Round <n>. Previous round asked for: <one line, or "first round">.

Read the target yourself with git:
  git log <range>
  git diff <range>
(commit: `git show <sha>`, files with `git show <sha>:<path>` · uncommitted: `git diff HEAD`
plus `git status --short`)

Open these yourself — they are paths, not quoted here:
- conventions: <path>   (if the repo batches comment approval at the end of a workstream, that is
  stated there — do not file "no approval evidence")
- structure map: <path>
- self-report: <path>   (judge whether the rebuttals in it are correct)
- previous review: .claude/tmp/codex-review-<name>-r<n-1>.md   (round 2 and later)
Anything under `.claude/tmp/` is gitignored: `git show` cannot open it, `cat` can.

Run before judging: <check command>

Structure — callers, a file's API, the directory map — comes from the graft index:
`graft_trace_calls` (`depth: "all"` for a rename), `graft_file_api`, `graft_repo_map`. On `no
graph found` or `no symbol "X" in the graph` this repo has no index or that language is not
parsed: use the LSP tools and `grep-block`, and say so. Empty graft output is a fact about the
index, not "there are none".

`graph` answers only "was this already judged, what was left unfollowed". Pass this repository's
path — an unnamed `graph` answers for another project — and report an empty answer as `never
traced` or `traced, no such edge`, never as a reason to sweep wide. MCP tools read the working
tree, not the reviewed commit: background only, and a finding resting on one must say it is
working-tree state that may differ from the commit. `trace` writes to that store: call it only
when a relation this review turns on is missing from it, scope it with `path`, and pass `ask`
with this review's name in it.

Do not write, create or modify any file. Your reply is the review; it is captured to a file for
you.

The structure map has three jobs:
1. Read its invariants — the rules and the test guarding each. Structure itself is not here:
   ask the graft index.
2. Judge whether the diff left it stale — a new type, seam or invariant the map lacks is a
   finding, same as a missing test.
3. Close every `?` row — confirmed, wrong, or still unreachable. A `?` surviving a round
   unexamined is itself a finding.

Do not limit the kinds of things to look for — defects, design deviations, convention violations,
missed spots, dead code, fake safeguards; anything with code evidence. Lists claimed "exhaustive":
count and verify yourself.

Write in **English**, **caveman style**. Drop articles, qualifiers, hedges; state facts only.
Fragments fine. One finding = one-line gist + `file:line` + one or two lines of evidence. Do not
restate. Quote code and `file:line` exactly. End with `Verdict: pass | needs changes | unresolved`
and counts `P1 n · P2 n · P3 n`.
```

The English instruction is **unreliable** — Codex has answered in Korean with that line present
(2026-09-12). Keep the line; do not treat English output as guaranteed.

### Field of view — two different things

**The kinds of findings stay open.** No "look only at these" list: the reviewer's view shrinks to
the caller's suspicion range and the round returns nothing.

**The reading target stays pinned to the review range.** Never write a scope sentence that widens
it. Observed 2026-09-12: "Scope: the whole of src/ and tests/. Do not restrict the review to the
changed files" turned a one-commit review into a whole-tree audit.

## Step 2 — Run Codex

**Background job** (`run_in_background: true`), no separate `sleep`. A round takes 2–10 minutes,
and a foreground run blocks the conversation for all of it. The harness re-invokes you when the
command exits; do not poll for it. Keep working or answer the user in the meantime, and go to
Step 3 only after the completion notification.

```bash
codex exec --approve-for-me -C <repo> --color never \
  -o .claude/tmp/codex-review-<name>-r<n>.md \
  "$(cat .claude/tmp/codex-prompt-<name>-r<n>.md)" < /dev/null \
  > .claude/tmp/codex-run-<name>-r<n>.log 2>&1
```

**`< /dev/null` is mandatory.** codex reads extra input from stdin when stdin is not a TTY, and a
multi-line Bash command is fed through stdin by the harness; without the redirect it blocks on
"Reading additional input from stdin..." until timeout (observed: 600 s, zero output).

**`--approve-for-me`, not `--sandbox read-only`.** `codex exec` is non-interactive, so it pins the
approval policy to `never` and every MCP call dies on `MCP tool call requires approval, but
approval policy is never`; `-c approval_policy=...` does not override it (codex-cli 0.154.0).
`--approve-for-me` routes approvals through an automatic review and raises the sandbox to
`workspace-write [workdir, /tmp, $TMPDIR]` — so the sandbox no longer stops the reviewer writing,
only the prompt does, and each approved call costs an extra model pass.

**If the permission classifier refuses it** — in an auto-mode session this environment can deny
`--approve-for-me` as "Create Unsafe Agents" (observed 2026-09-12) — fall back to `--sandbox
workspace-write`. That loses the MCP approval elevation but still produces findings. Say which one
ran.

**Not `codex exec review`**: its `--commit` cannot be combined with a custom prompt and it has no
`--color` (codex-cli 0.153.2).

## Step 3 — Read the result

Read `.claude/tmp/codex-review-<name>-r<n>.md`. A round's review runs about 2 KB.

**A spent usage limit exits 0 with no `-o` file.** The log's last line reads `ERROR: You've hit
your usage limit … try again at <date>`, yet the command exits 0, so an exit-code check calls it
success. When the `-o` file is missing, `grep -i "usage limit"` the run log before anything else.
Report the retry date; do not retry. Such a run can also sit for over an hour (observed
2026-09-05: 73 minutes, killed by hand) — treat more than 15 minutes with no `-o` file as failed.
A trivial probe (`codex exec --sandbox read-only --color never "say OK"`) still answers on a spent
quota, so trust the log line, not the probe.

Exit nonzero or an empty output file: report the failure as it is. Do not retry more than once.

## Step 4 — Report

```
Verdict: <pass | needs changes | unresolved>
Counts: P1 n · P2 n · P3 n
Full text: .claude/tmp/codex-review-<name>-r<n>.md

[P2] <one-line gist> — <file:line>
[P3] <one-line gist> — <file:line>
```

No findings → omit the findings lines and report `Verdict: pass`.

**Do not verify the findings here.** Report what Codex said, with its own `file:line` citations,
compressed to the gist and not re-derived. Confirming a finding against the source is the next
step of the work cycle; doing it inside the review pays for the same read twice. Measured
2026-09-12: a round cost 105k tokens over 45 tool calls, most of them re-opening files Codex had
already read and the caller then read again.

Relay the verdict as it stands. It looks like a false positive: **append** that, do not erase the
reviewer's words.

## Not this

- Do not modify source here. Applying findings is the caller's next step.
- Never `git restore`, `checkout`, `reset`, `stash` — the tree may be staged for the next task.

## When Codex is unavailable

Usage limit hit, CLI missing, run failed → use the `fable-review` agent, same review contract on
Fable. Say which one produced the result.
