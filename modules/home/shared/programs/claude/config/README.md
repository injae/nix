# Claude Code Config

Nix-managed source of truth for `~/.claude/`.

## Structure

- `CLAUDE.md`: global instructions
- `settings.json`: Claude Code settings
- `hooks/`: settings hooks (`settings.json` `hooks`) for the `classic.*`
  events, which the organization's managed `cc-plugin-sec-default` plugin
  routes past user-tier mods:
  - `context/`: session-start directives, exploration reminder, shell-plan guard (Stop)
  - `skills/`: skill activation at session start, per-prompt skill reminder
  - `direnv/`: `direnv reload` on start, cwd change and `.envrc` edit
  - `emacs/emacs-buffer-context.py`: active-buffer context per prompt
  - `emacs/elisp-check-parens.py`: paren checker the `emacs-mcp-dev` skill runs
- `skills/`: local skills
- `../mods/`: hook mods (function-hook plugins) on native events, each linked
  by `../default.nix` as one directory into `~/.claude/skills/` and loaded as
  `<name>@skills-dir`:
  - `emacs-sync`: edit sync to Emacs, inline-edit guard
  - `compact-guard`: `ctx N%` status, warning band from 70%, auto compact at 75%
  - `work-units`: `begin_work_unit` tool, per-unit compaction, `/units` pane

  Each has `tests/`; run `claude plugin test <dir>`.

## Upstream skills and plugins

Third-party skills and plugins are not vendored here; they are pinned
derivations symlinked into `~/.claude/skills/` by `../default.nix`:

- `packages/vercel-agent-skills.nix`: the four Vercel skills
- `packages/superpowers-plugin.nix`: loaded as `superpowers@skills-dir`
- `packages/caveman-plugin.nix`: loaded as `caveman@skills-dir`, and provides
  the `statusLine` script at `~/.claude/skills/caveman/src/hooks/caveman-statusline.sh`
- `packages/codex-plugin.nix`: the `plugins/codex` subtree of the
  `openai/codex-plugin-cc` marketplace repo, loaded as `codex@skills-dir`

Update flow: bump `version`/`tag` and `hash` in the package file.
