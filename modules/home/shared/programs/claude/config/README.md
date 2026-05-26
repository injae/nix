# Claude Code Config

Nix-managed source of truth for `~/.claude/`.

## Structure

- `CLAUDE.md`: global instructions
- `settings.json`: Claude Code settings
- `hooks/`: lifecycle hooks (nix-managed symlinks + caveman plugin files)
- `skills/`: local skills

## Caveman plugin hooks

`caveman@caveman` writes hook files directly into `~/.claude/hooks/`:
- `caveman-activate.js`
- `caveman-mode-tracker.js`
- `caveman-stats.js`
- `caveman-statusline.sh`
- `caveman-statusline.ps1`
- `caveman-config.js`

Reason: plugin installer uses `fs.copyFileSync`; nix store symlink target is read-only, so plugin update can fail with `EROFS`.

Update flow: copy updated hook files from
`~/.claude/plugins/marketplaces/caveman/src/hooks/`
into this repo `hooks/`, then commit.
