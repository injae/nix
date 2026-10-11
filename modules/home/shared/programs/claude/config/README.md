# Claude Code Config

Nix-managed source of truth for `~/.claude/`.

## Structure

- `CLAUDE.md`: global instructions
- `settings.json`: Claude Code settings
- `hooks/emacs/elisp-check-parens.py`: paren checker the `emacs-mcp-dev` skill runs
- `skills/`: local skills
- `../mods/`: hook mods (function-hook plugins) that replace settings hooks,
  each linked by `../default.nix` as one directory into `~/.claude/skills/`
  and loaded as `<name>@skills-dir`:
  - `session-context`: session-start directives, per-prompt reminders, shell-plan guard
  - `emacs-sync`: active-buffer context, edit sync to Emacs, inline-edit guard
  - `direnv-sync`: `direnv reload` on start, cwd change and `.envrc` edit
  - `compact-guard`: `ctx N%` status, warning band from 70%, auto compact at 75%
  - `work-units`: `begin_work_unit` tool, per-unit compaction, `/units` pane

  Each has `tests/`; run `claude plugin test <dir>`. `settings.json` sets
  `"hooks": null`, which `../merge-json.py` turns into removing the key.

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
