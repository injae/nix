---
name: skill-creator
description: "Guide for writing and editing skills. Use whenever creating a new skill or modifying an existing one. Sequential workflow skills (step-by-step, branching, tool selection) follow the style documented in sequential.md."

---

# Skill Creator

## Step 1 — Determine the skill type

Before writing, answer: **does this skill describe a sequential workflow?**

- **YES** — execution order matters, has decision points or branching → read `sequential.md` for the style guide
- **NO** — reference doc, pattern collection, style guide → use free-form Markdown

---

## Step 2 — File structure

```
skill-name/
├── SKILL.md       required. frontmatter + body
└── *.md           optional. split-out reference files (e.g. sequential.md, synctest.md)
```

Keep SKILL.md under 500 lines. Move detailed content to separate files and state explicitly when to read them.

---

## Step 3 — Frontmatter

```yaml
---
name: skill-name
description: "Trigger conditions + what the skill does. Use this skill whenever the user asks about X."
disable-model-invocation: true   # optional: hide from auto-loading; users can still invoke by command
---
```

`description` is the primary trigger mechanism — include both what the skill does and when to use it.

---

## Step 4 — Writing principles

- Use imperative voice ("Read the file", "Call the tool")
- Explain *why* instead of writing MUST/NEVER in caps — when the model understands the reason, it can handle edge cases on its own
- Make examples concrete: real file paths, real values, real error messages
- Make every branch explicit: "If YES → X, if NO → Y"
- Put shared content in SKILL.md; put variant-specific detail in separate files
- When referencing emacs-tools MCP tools, use the shorthand name (e.g., `` `goto-line` ``, `` `lsp-def` ``) instead of harness-specific tool identifiers.

---

## Step 5 — Compression/edit workflow (approved pattern)

Use this loop when compressing existing skill docs without semantic loss.

1. Work one file at a time.
2. Create a compressed draft first (wording-only compression; keep all rules/branches/examples/conditions).
3. Show a short unified diff first (no color required).
4. If the user asks, show full **After** text with no `...` truncation.
5. Do not write until explicit approval (`수정`/`적용`).
6. After write completes, automatically move to the next file and show draft + short diff.

Guardrails:
- Never drop constraints or decision branches during compression.
- Keep document language consistent with original (English doc stays English, etc.).
- If approval scope is unclear, ask before writing.