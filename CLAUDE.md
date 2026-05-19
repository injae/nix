# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
just switch          # Apply configuration to current host (nix run .#activate)
just update          # Update all flake inputs (nixpkgs, home-manager, etc.)
just hostname        # Show current machine hostname
just get-sha256 URL  # Get SRI hash for a URL (useful for package definitions)
```

Formatting is handled by `treefmt` (nixfmt for .nix files). Run via the devshell: `nix develop`.

## Architecture

This is a multi-host, multi-platform Nix flake configuration using **flake-parts** and **nixos-unified**.

### Host configurations
Machine-specific configs live in `configurations/{platform}/{hostname}/`.
The flake uses `nixos-unified`'s `autoWire` to automatically wire all `configurations/` into flake outputs. `just switch` runs `.#activate` which applies the config for the current hostname.

### Module hierarchy

```
configurations/     # Host-specific configurations (one per machine)
  darwin/           # nix-darwin host configs
    - {hostname}    # hostname with .local stripped
  nixos/            # nixos host configs
    - {hostname}    # hostname
modules/
  flake-parts/     # FlakeParts modules: nixos-unified wiring, devshell, treefmt, people config
  home/            # Home Manager modules (shared across machines, with platform-specific subdirs)
    shared/        # Cross-platform Home Manager modules (auto-imported via readDir)
      coding/      # Language toolchains: nix, terraform, gleam, go, rust, python, js
      programs/    # General programs (terminal, sops, emacs, font, etc.)
      packages.nix # Miscellaneous packages
    darwin/        # Darwin-only home modules (colima, etc.)
  shared/          # Cross-platform nix system modules (nix settings, caches)
  nixos/           # nixos-specific system modules
  darwin/          # nix-darwin system modules (dock, homebrew, ollama, etc.)
overlays/          # Custom package overlays (mov2gif, img2webp, dl-yt, etc.)
packages/          # Custom Nix package derivations
templates/         # Dev environment templates (go, rust, python, cpp, bazel, etc.)
scripts/           # Utility scripts (e.g., for packages)
```

### Auto-import pattern

Directories use `builtins.readDir` to auto-import all `.nix` files, with an `exclude` list for `default.nix` itself:
```nix
map (fn: ./${fn}) (filter (fn: !(elem fn exclude)) (attrNames (readDir ./.)))
```
Adding a new `.nix` file to `modules/home/shared/programs/` or similar directories is sufficient — no explicit import needed.

### User identity

`config.nix` defines users (name, email, SSH keys). The `modules/flake-parts/config.nix` exposes this as `flake.config.people`, which is injected throughout modules (e.g., git user config, authorized SSH keys).

### Secrets

SOPS-encrypted secrets in `modules/home/shared/programs/sops/secrets/`. Age keys derived from SSH ed25519 keys. `.sops.yaml` maps host public keys to encrypted files. Use `just init-key` on a new machine to derive the age key.

### Claude Code configuration

Claude Code settings, skills, and global instructions are managed in `modules/home/shared/programs/claude/config/`, which is symlinked to `~/.claude/` via Home Manager. When adding or modifying Claude Code configuration (CLAUDE.md, settings.json, skills, commands, hooks), always edit files in this directory — not directly in `~/.claude/`. Run `just switch` to apply changes.

For temporary or experimental instructions that should take effect immediately (without `just switch`), edit `~/.claude/CLAUDE.local.md` directly. This file is not Nix-managed and is loaded automatically at session start. Do not commit it.

### Emacs configuration

The Emacs config is a full Elisp setup in `modules/home/shared/programs/emacs/config/`. Modules are organized under `config/module/` with prog language modules in `config/module/prog/`. The LSP layer uses **eglot** with a custom `rass` wrapper for go/rust/yaml/nix, and language-specific servers for others. `eglot-server-programs` entries are spread across the relevant language module files.

#### MCP tools (`config/module/mcp/`)

Custom MCP tools exposed to Claude Code via `claude-code-ide` live in `config/module/mcp/`. Each file defines a tool function and registers it by calling `claude-code-ide-make-tool` at the top level (which runs after `claude-code-ide` is loaded, inside `+ai.el`'s `:config` block).

`config/module/+ai.el` loads all mcp modules via:
```elisp
(load-modules-with-list (f-join user-emacs-module-directory "mcp") '(describe-symbol))
```

To add a new MCP tool:
1. Create `config/module/mcp/+<name>.el` — define functions, call `claude-code-ide-make-tool`
2. Add `<name>` to the list in `+ai.el`
