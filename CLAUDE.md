# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

**CRITICAL: Never run `just switch` unless the user explicitly asks for it. Do not suggest it either.**

---

## Architecture

This is a multi-host, multi-platform Nix flake configuration using **flake-parts** and **nixos-unified**.

To add a new host: Create `configurations/{darwin|nixos}/{hostname}/default.nix`

---

### Module hierarchy

```
configurations/       # Host-specific configurations (one per machine)
  darwin/             # nix-darwin host configs
    - {hostname}/     # hostname with .local stripped
       -  default.nix
  nixos/              # nixos host configs
    - {hostname}      # hostname
       -  default.nix
modules/
  flake-parts/        # FlakeParts modules: nixos-unified wiring, devshell, treefmt, people config
  home/               # Home Manager modules (shared across machines, with platform-specific subdirs)
    shared/           # Cross-platform Home Manager modules (auto-imported via readDir)
      coding/         # Language toolchains: nix, terraform, gleam, go, rust, python, js
      programs/       # General programs (sops, emacs, font, claude, etc.)
      packages.nix    # Miscellaneous packages
    darwin/           # Darwin-only home modules (colima, etc.)
  shared/             # Cross-platform nix system modules (nix settings, caches)
  nixos/              # nixos-specific system modules
  darwin/             # nix-darwin system modules (dock, homebrew, ollama, etc.)
overlays/             # Custom package overlays (mov2gif, img2webp, dl-yt, etc.)
packages/             # Custom Nix package derivations
templates/            # Dev environment templates (go, rust, python, cpp, bazel, etc.)
scripts/              # Utility scripts (e.g., for packages)
```

---

### Auto-import pattern

Directories use `builtins.readDir` to auto-import all `.nix` files, with an `exclude` list for `default.nix` itself:

```nix
map (fn: ./${fn}) (filter (fn: !(elem fn exclude)) (attrNames (readDir ./.)))
```

To add a new module to an auto-imported directory (e.g. `modules/home/shared/programs/`):
1. Create the `.nix` file in the target directory — no explicit import needed
2. Run `git add <file>`

---

### Claude Code configuration (`modules/home/shared/programs/claude/config/`)

Claude Code settings, skills, and global instructions live in `modules/home/shared/programs/claude/config/`, symlinked to `~/.claude/` via Home Manager.
Never edit `~/.claude/` directly — those changes are overwritten on `just switch`.

To add or modify Claude Code configuration (CLAUDE.md, settings.json, skills, hooks):
1. Edit files under `modules/home/shared/programs/claude/config/`
2. Run `just switch` to apply

For temporary instructions that should take effect immediately (without `just switch`), edit `~/.claude/CLAUDE.local.md` directly.
This file is not Nix-managed and is loaded at session start.
Do not commit it.

---

### Emacs configuration (`modules/home/shared/programs/emacs/config/`)

The Emacs config is a full Elisp setup in `modules/home/shared/programs/emacs/config/`.
Modules are organized under `config/module/` with prog language modules in `config/module/prog/`.
The LSP layer uses **eglot** with a custom `rass` wrapper for go/rust/yaml/nix, and language-specific servers for others.
`eglot-server-programs` entries are spread across the relevant language module files.

To add a new Emacs module:
1. Create `config/module/+<name>.el` (or `config/module/prog/+<name>.el` for language modules)
2. Run `git add <file>` — the module directory is auto-loaded
