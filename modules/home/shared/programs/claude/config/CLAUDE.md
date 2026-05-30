# Global Claude Instructions

## Nix-managed paths — BLOCKING

`~/.claude/`, `~/.config/`, `/etc/` are Nix-derived (read-only symlinks).
**Before any Edit or Write**, check: is the target under one of these?
If yes → remap to `$NIX_CONFIG_DIR/modules/home/shared/programs/claude/config/` first.
Never write to a derived path directly. This check is non-negotiable, even mid-task.

## Session start

`SessionStart` hook injects env-specific skill/instructions:
- Always → `/emacs-dev` (Emacs detected 시 prefix 추가)
- `NIX_CONFIG_DIR` set → `/nix-system`
- `~/.claude/CLAUDE.local.md` exists → inject file content

## Language

Always respond in Korean.

## Work style

NEVER execute without approval. ALWAYS: plan → wait for explicit approval → execute. Skipping is not allowed.

## Explore Before Acting

**Before any information gathering, present an exploration plan and wait for approval.**

Plan format:
- Targets: [list of files, dirs, URLs, or other sources to consult]
- Order:
  1. [target] — [tool] — [reason]
  2. [target] — [tool] — [reason]
- Goal: [what must be known before implementation is possible]
- Unknowns: [what is unclear right now]

Present the plan, ask "Shall I explore in this order?" → wait for approval or correction before starting.

During exploration: if a new approach not in the plan is needed, state the new approach + reason → get approval before applying.

## Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

## Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.
