#!/usr/bin/env python3
import os
import json

parts = []

e = os.environ.get("INSIDE_EMACS", "")
t = os.environ.get("TERM_PROGRAM", "")
if e or t == "emacs":
    parts.append(
        f"MANDATORY SESSION START: Emacs detected (INSIDE_EMACS={e}). "
        "You MUST invoke the /emacs-dev skill before responding to the user."
    )

nix_config = os.environ.get("NIX_CONFIG_DIR", "")
cwd = os.getcwd()
has_flake = os.path.exists(os.path.join(cwd, "flake.nix"))
has_envrc = os.path.exists(os.path.join(cwd, ".envrc"))
if nix_config or (has_flake and has_envrc):
    reason = (
        f"NIX_CONFIG_DIR={nix_config}"
        if nix_config
        else "flake.nix + .envrc detected in CWD"
    )
    parts.append(
        f"MANDATORY SESSION START: Nix environment detected ({reason}). "
        "You MUST invoke the /nix-system skill before responding to the user."
    )

lf = os.path.expanduser("~/.claude/CLAUDE.local.md")
if os.path.exists(lf):
    c = open(lf).read().strip()
    if c:
        parts.append(f"CLAUDE.local.md:\n{c}")

if parts:
    print(
        json.dumps(
            {
                "hookSpecificOutput": {
                    "hookEventName": "SessionStart",
                    "additionalContext": "\n\n".join(parts),
                }
            }
        )
    )
