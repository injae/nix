# Claude Code Config (Nix-managed)

Source path: `$NIX_CONFIG_DIR/modules/home/shared/programs/claude/config/`

Structure:
- `CLAUDE.md` — global instructions
- `settings.json` — Claude Code settings
- `skills/` — skill definitions (each in its own subdirectory with `SKILL.md`)
- `hooks/` — settings hooks registered in `settings.json` (`classic.*` events, which the managed `cc-plugin-sec-default` plugin routes past user mods), plus `emacs/elisp-check-parens.py`
- `../mods/` — hook mods (function-hook plugins on native events), each linked as one directory into `~/.claude/skills/<name>` by `../default.nix`; add a new mod there too (see `README.md`)

`CLAUDE.local.md` is NOT Nix-managed — edit `~/.claude/CLAUDE.local.md` directly for temporary instructions that take effect without `just switch`.