# Claude Code Config

Nix-managed source of truth for `~/.claude/`.

## Structure

- `CLAUDE.md`: global instructions
- `settings.json`: Claude Code settings
- `hooks/`: lifecycle hooks
- `skills/`: local skills

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
