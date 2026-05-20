#!/usr/bin/env bash
# SessionStart hook: detect Emacs environment and inject CLAUDE.local.md

python3 - <<'EOF'
import os, json

parts = []

e = os.environ.get('INSIDE_EMACS', '')
t = os.environ.get('TERM_PROGRAM', '')
if e or t == 'emacs':
    parts.append(
        f"MANDATORY SESSION START: Emacs detected (INSIDE_EMACS={e}). "
        "You MUST invoke the /emacs-dev skill before responding to the user."
    )

lf = os.path.expanduser('~/.claude/CLAUDE.local.md')
if os.path.exists(lf):
    c = open(lf).read().strip()
    if c:
        parts.append(f"CLAUDE.local.md:\n{c}")

if parts:
    print(json.dumps({
        'hookSpecificOutput': {
            'hookEventName': 'SessionStart',
            'additionalContext': '\n\n'.join(parts)
        }
    }))
EOF
