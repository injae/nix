# Claude Code Config (Nix-managed)

Source path: `$NIX_CONFIG_DIR/modules/home/shared/programs/claude/config/`

Structure:
- `CLAUDE.md` — global instructions
- `settings.json` — Claude Code settings
- `skills/` — skill definitions (each in its own subdirectory with `SKILL.md`)
- `../mods/` — hook mods (function-hook plugins that replace settings hooks), each linked as one directory into `~/.claude/skills/<name>` by `../default.nix`; add a new mod there too (see `README.md`)
- `hooks/emacs/elisp-check-parens.py` — the one remaining script; there are no settings hooks (`"hooks": null`)

`CLAUDE.local.md` is NOT Nix-managed — edit `~/.claude/CLAUDE.local.md` directly for temporary instructions that take effect without `just switch`.