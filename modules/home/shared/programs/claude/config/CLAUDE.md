# Global Claude Code Instructions

## Session start

At the start of every session:

1. Invoke `/emacs-dev` to check for Emacs environment and configure MCP tools.
2. Check whether `~/.claude/CLAUDE.local.md` exists via Bash. If it exists, read and apply its contents as additional instructions for this session.
3. If `NIX_CONFIG_DIR` is set in the environment, note that path for use in the section below.

## Nix / system / Emacs configuration work

When the task involves editing Nix configuration, system settings, or Emacs configuration (e.g. `.nix` files, Home Manager modules, nix-darwin modules, NixOS modules, or Emacs `.el` config files), and `NIX_CONFIG_DIR` is set:

- Read `$NIX_CONFIG_DIR/CLAUDE.md` at the start of the task and treat it as the authoritative project instructions for that work.
- All edits must target files under `$NIX_CONFIG_DIR`, not `~/.config` or other derived paths, unless the file is explicitly not Nix-managed.
- Claude Code configuration (CLAUDE.md, settings.json, skills, hooks) is managed under `$NIX_CONFIG_DIR/modules/home/shared/programs/claude/config/`. Always edit files there, not directly in `~/.claude/`.
- **Never run `just switch` yourself.** The user will run it manually when ready — do not remind them, and do not mention it as a closing remark (e.g. "takes effect after just switch").
- When creating a new file anywhere under `$NIX_CONFIG_DIR`, immediately run `git add <file>` afterward. Nix flakes only see files tracked by git, so untracked files are silently ignored.

## Language

Always respond in Korean.

## Work style

Before starting any task, always explain the planned steps first, then proceed.

## Elisp editing

When editing `.el` files, always verify parenthesis balance before finishing any edit.

**In Emacs mode** (when `mcp__emacs-tools__claude-code-ide-mcp-call-function` is available), call the helper via `call-function`:

- function: `claude-code-ide-mcp-check-elisp-parens`
- args_json: `["CODE_HERE"]`

Returns `t` if balanced, or an error string if not. **Otherwise** (non-Emacs mode), count `(` and `)` in every expression written.
