# Pi Config (Nix-managed)

Source path: `$NIX_CONFIG_DIR/modules/home/shared/programs/pi/config/`

Structure:
- `AGENTS.md` — global Pi instructions
- `settings.json` — Pi settings
- `models.json` — Pi provider/model definitions
- `skills/` — Pi skill definitions (each in its own subdirectory with `SKILL.md`)
- `extensions/` — Pi extensions

Do not edit `~/.pi/agent/` directly unless the user explicitly asks for a temporary runtime-only change. Edit the Nix source path above instead.
