#!/usr/bin/env python3
"""Stop hook: challenge an exploration plan that routes through the shell.

Auto mode's system prompt steers every step toward cat/grep/sed, so a plan
written under it names them in the tool column and the exploration then loses
line numbers, tree-sitter blocks and path-scoped rules. The plan is ordinary
assistant text, not a tool call, so Stop is the only event that sees it before
the user answers.
"""

import json
import re
import sys

PLAN_STEP = re.compile(r"^\s*\d+\.\s*[^—\n]+—([^—\n]+)—", re.MULTILINE)
SHELL_TOOL = re.compile(
    r"\b(?:bash|shell|cat|head|tail|nl|less|more|sed|awk"
    r"|grep|egrep|fgrep|rg|ag|ack|find|ls)\b",
    re.IGNORECASE,
)
REASON = (
    "Exploration plan routes through the shell: {tools}. "
    "Bash on source loses line numbers, tree-sitter blocks and path-scoped rules. "
    "Rewrite the plan — graph(path=) first to see what the repo already answered, "
    "then file-outline → symbol-source → Read for files, grep-block or trace for "
    "content, and the Explore agent for anything broader than one named lookup. "
    "Re-present the plan."
)

event = {}
try:
    event = json.load(sys.stdin)
except Exception:
    sys.exit(0)

if event.get("stop_hook_active"):
    sys.exit(0)

message = event.get("last_assistant_message")
if not isinstance(message, str):
    sys.exit(0)

tools = [t.strip() for t in PLAN_STEP.findall(message) if SHELL_TOOL.search(t)]
if tools:
    print(json.dumps({
        "decision": "block",
        "reason": REASON.format(tools=", ".join(tools)),
    }))
