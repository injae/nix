---
name: axis-map
description: Keep a repository's invariants as a checked table (`docs/map/<axis>.md`), each rule naming the test that guards it, and check that those tests exist. Open it when writing down a rule the code must keep, or when updating or checking a map.
---

# Axis map — the rules a checker can confirm

One table per axis: a rule, and the test that guards it. Nothing else.

**It is a table, not prose.** People read it, but **agents parse it** — hence fixed columns and no
line numbers.

## What goes where

`docs/map/<axis>.md` — one page per axis. `<axis>` is the name of a top-level module of that
repository.

```markdown
---
axis: plant
root: src/plant/
---

## invariants

| rule | guarded-by |
|---|---|
| picking happens only when it bears | `picking_is_refused_on_a_day_the_bush_bears_nothing` |
```

**Conventions**

- **No line numbers.** Lines rot; names rot less. Find the position when you need it.
- **Test names in backticks.** That is all the checker looks at. For a `Type::method` form, it
  searches on the last segment.
- **No prose.** "Why it came to be this way" belongs in the design docs (`docs/design/`) and the
  PR body.
- `guarded-by` is **an actual test name**. A rule with nothing keeping it is not a rule — and has
  no row here.

## The rule that decides what belongs

**Keep only what the checker can confirm.**

`guarded-by` is a test name: rename or delete the guard and the gate turns red. That is the whole
reason this table survives.

Three things used to live here and no longer do, because nothing confirmed them:

- **`symbols`** — name, kind, file, a one-line description, and an `at` hash saying when the row
  was confirmed. Measured: 42 of `plant.md`'s 43 rows were unconfirmed, so "0 mismatches" meant
  "nobody looked". The descriptions were checked by nothing at all.
- **`seams`** — hand-written edges between symbols. One row still named a type the branch had
  deleted.
- **`head:`** — a commit SHA in the front matter. `check.py` never read it, and it went stale by
  hand twice in one session.

In one session (2026-09-12 to 13) these produced four `map-check` failures from line numbers an
explorer had written into rows, and two Codex review rounds filed map staleness as findings while
finding no code defect in the map's area. Stripping two maps took them from 113 and 90 lines to
34 and 33.

**Structure questions go to `graph()` and `trace`.** That is what the store is for: it records
what was actually traced, and it keeps never-traced apart from traced-and-empty. A hand-written
table of symbols cannot.

**The `?` row is gone with them.** It was a way to admit "exploration could not confirm this", for
a reviewer to close later — `transition.md` was carrying 29 of them, every one a symbol. An
invariant either names a test or does not belong in the table.

## Checking — a map lives only if it is checked

```bash
python3 ~/.claude/skills/axis-map/check.py [repo_root]
```

With no argument it looks at the current directory. It asks one question of every row: is
`guarded-by` a real test name (`fn <name>`) somewhere under `src/` or `tests/`. A mismatch exits 1.
Both roots are searched because a rule about production wiring — schedule order, plugin
registration — can only be guarded from `tests/`.

**Put it in the repository's standing checks** (`just check`, `make check`, CI, whatever) — a rule
with no check is not kept.

**What the check cannot see:**
1. **What is missing.** It only asks whether the names written down exist — put "did this diff
   leave the map stale?" in the review instructions.
2. **Meaning.** A test can exist while the rule beside it is wrong (measured: "`shed_dead_plants`
   — produces no yield" was **a description rather than a rule**, so nobody kept it).

## Who writes it

The workstream that establishes a rule writes its row, with the test that guards it, in the same
change. A rule arriving without its test does not go in the table — it goes in the work.

## When the first page is made

Do not build every axis at once. **The workstream that touches an axis makes that axis's first
page.**
