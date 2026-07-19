# Emacs Config (Nix-managed)

Source path: `$NIX_CONFIG_DIR/modules/home/shared/programs/emacs/config/`

Structure:
- `config/module/` — Emacs modules (auto-loaded via readDir)
- `config/module/prog/` — language-specific modules
- LSP layer uses **eglot** with a custom `rass` wrapper; server entries are in each language module

To add a new module: create `config/module/+<name>.el` (or `config/module/prog/+<name>.el`), then `git add <file>`.