# Claude Code Config (Nix-managed)

Source path: `$NIX_CONFIG_DIR/modules/home/shared/programs/claude/config/`

Structure:
- `CLAUDE.md` — global instructions
- `settings.json` — Claude Code settings
- `skills/` — skill definitions (each in its own subdirectory with `SKILL.md`)
- `hooks/` — lifecycle hooks (session-start, pre-compact, stop, etc.)

`CLAUDE.local.md` is NOT Nix-managed — edit `~/.claude/CLAUDE.local.md` directly for temporary instructions that take effect without `just switch`.