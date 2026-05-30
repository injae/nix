#!/usr/bin/env python3
import os
import sys
import json
import glob

event = {}
try:
    event = json.load(sys.stdin)
except Exception:
    pass

trigger = event.get("trigger", "")
parts = []

# Compact restore: inject saved checkpoint context into the new window
if trigger == "compact":
    checkpoints = sorted(
        glob.glob(os.path.expanduser("~/.claude/checkpoints/checkpoint-*.json")),
        reverse=True,
    )
    if checkpoints:
        try:
            with open(checkpoints[0]) as f:
                cp = json.load(f)
            ctx = f"## Restored from compact checkpoint ({cp['timestamp']})\n- Working directory: {cp['cwd']}"
            if cp.get("todos"):
                pending = [t for t in cp["todos"] if isinstance(t, dict) and t.get("status") != "completed"]
                if pending:
                    ctx += f"\n\n## Pending TODOs\n{json.dumps(pending, ensure_ascii=False, indent=2)}"
            parts.append(ctx)
        except Exception:
            pass

e = os.environ.get("INSIDE_EMACS", "")
t = os.environ.get("TERM_PROGRAM", "")
if e or t == "emacs":
    parts.append(f"Emacs detected (INSIDE_EMACS={e}).")
parts.append(
    "MANDATORY SESSION START: You MUST invoke the /emacs-dev skill before responding to the user."
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
