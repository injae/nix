#!/usr/bin/env python3
"""PreToolUse hook: refuse shell commands that edit files invisibly.

A heredoc fed to an interpreter, an inline -c/-e program, or an in-place
stream edit changes files without going through Edit or Write. Nothing
records what changed, the PostToolUse sync never runs, and the language
server keeps serving pre-edit text.

Write the script to a file and run that file instead: the write is visible,
the sync hook fires, and the script survives for a second run.

Blocks with exit code 2, which hands the message back to Claude.
"""

import json
import re
import sys

RULES = [
    (
        "heredoc fed to an interpreter",
        r"\b(?:python3?|perl|ruby|node|osascript|bash|sh|zsh)\b[^|;&\n]*<<-?\s*[\"']?\w",
    ),
    (
        "inline interpreter program (-c / -e)",
        r"\b(?:python3?\s+(?:-\w+\s+)*-c|(?:perl|ruby|node)\s+(?:-\w+\s+)*-e)\b",
    ),
    (
        "heredoc redirected into a file",
        r">>?\s*\S+[^\n]*<<-?\s*[\"']?\w|<<-?\s*[\"']?\w[^\n]*>>?\s*\S|\btee\b[^\n]*<<-?\s*[\"']?\w",
    ),
    (
        "in-place stream edit",
        r"\bsed\b[^|;&\n]*\s-i(?:\b|\.)|\bawk\b[^\n]*-i\s*inplace",
    ),
]

GUIDANCE = (
    "Write the program to a file with the Write tool and run that file, "
    "or make the edit with Edit / ast-rewrite. "
    "Reading heredocs that touch no file stay allowed."
)


def main() -> None:
    try:
        event = json.load(sys.stdin)
    except Exception:
        return

    command = (event.get("tool_input") or {}).get("command")
    if not command:
        return

    for name, pattern in RULES:
        if re.search(pattern, command):
            print(f"Blocked: {name}. {GUIDANCE}", file=sys.stderr)
            sys.exit(2)


if __name__ == "__main__":
    main()
