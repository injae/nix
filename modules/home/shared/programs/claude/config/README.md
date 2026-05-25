# Claude Code Config

Nix-managed Claude Code configuration. Source of truth for `~/.claude/`.

## Structure

```
CLAUDE.md          — global instructions
settings.json      — Claude Code settings
hooks/             — lifecycle hook scripts (nix-managed symlinks)
skills/            — local skill definitions
```

## Hook scripts

Nix-managed hooks in `hooks/` are symlinked to `/nix/store/` (read-only).

### Caveman plugin hooks

The `caveman` plugin (`caveman@caveman`, GitHub: JuliusBrussee/caveman) installs
hook scripts directly into `~/.claude/hooks/` as regular files:

- `caveman-activate.js`
- `caveman-mode-tracker.js`
- `caveman-stats.js`
- `caveman-statusline.sh`
- `caveman-statusline.ps1`
- `caveman-config.js`

These coexist with nix-managed symlinks in the same directory.

**Why not managed by nix:** The plugin's `bin/install.js` uses `fs.copyFileSync`
to write hook files. If these were nix symlinks (read-only store), `claude plugin update`
would fail with `EROFS`. Plugin updates are manual-only (`/plugin update caveman`),
not automatic, so the risk of accidental overwrite is low.

**To update caveman hooks manually:** copy updated files from
`~/.claude/plugins/marketplaces/caveman/src/hooks/` to this directory and
commit them here instead.
