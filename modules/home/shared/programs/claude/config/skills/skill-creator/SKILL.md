---
name: skill-creator
description: "Guide for writing and editing skills. Use whenever creating a new skill or modifying an existing one. Sequential workflow skills (step-by-step, branching, tool selection) follow the style documented in sequential.md."
user-invocable: true
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
user-invocable: true   # add if the skill can be called directly via /skill-name
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
- When referencing emacs-tools MCP tools, use the shorthand name (e.g., `` `goto-line` ``, `` `lsp-def` ``) — never the full `mcp__emacs-tools__` prefix. Exception: `allowed-tools` frontmatter requires the full identifier.