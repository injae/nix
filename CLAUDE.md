# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## New files require `git add`

Nix flakes only evaluate files tracked by git.
After creating any new file in this repo, immediately run:

```bash
git add <file>
```

Without this, Nix silently ignores the file and changes appear to have no effect.

---

## Commands

```bash
just switch          # Apply configuration to current host (nix run .#activate)
just update          # Update all flake inputs (nixpkgs, home-manager, etc.)
just hostname        # Show current machine hostname
just get-sha256 URL  # Get SRI hash for a URL (useful for package definitions)
```

---

## Architecture

This is a multi-host, multi-platform Nix flake configuration using **flake-parts** and **nixos-unified**.

### Host configurations (`configurations/{platform}/{hostname}/`)

Machine-specific configs live in `configurations/{platform}/{hostname}/`.
The flake uses `nixos-unified`'s `autoWire` to wire all configurations into flake outputs automatically.
`just switch` applies the config for the current hostname via `.#activate`.

To add a new host:
1. Create `configurations/{darwin|nixos}/{hostname}/default.nix`
2. Run `git add` on the new file
3. Run `just switch` on the target machine

---

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

### User identity (`modules/flake-parts/config.nix`)

`modules/flake-parts/config.nix` defines users (name, email, SSH keys) and exposes them as `flake.config.people`, injected throughout modules (e.g., git user config, authorized SSH keys).

---

### Secrets (`modules/home/shared/programs/sops/secrets/`)

SOPS-encrypted secrets live in `modules/home/shared/programs/sops/secrets/`.
Age keys are derived from SSH ed25519 keys.
`.sops.yaml` maps host public keys to encrypted files.

To add a new secret:
1. Add the host's public key to `.sops.yaml` if not already present
2. Run `just init-key` on a new machine to derive the age key
3. Encrypt with `sops` and place the file under `secrets/`

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

#### Emacs MCP tools (`config/module/mcp/`)

Custom MCP tools that Emacs exposes to Claude Code via `claude-code-ide` live in `config/module/mcp/`.
These are Emacs-side tools (not general MCP servers) — each file defines a tool function and registers it by calling `claude-code-ide-make-tool` at the top level (which runs after `claude-code-ide` is loaded, inside `+ai.el`'s `:config` block).

`config/module/+ai.el` loads all mcp modules via:

```elisp
(load-modules-with-list (f-join user-emacs-module-directory "mcp") '(describe-symbol))
```

To add a new MCP tool:
1. Create `config/module/mcp/+<name>.el` — define functions, call `claude-code-ide-make-tool`
2. Add `<name>` to the list in `+ai.el`
