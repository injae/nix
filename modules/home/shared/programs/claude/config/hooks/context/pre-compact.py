#!/usr/bin/env python3
import sys
import json
import os
import glob
from datetime import datetime

event = {}
try:
    event = json.load(sys.stdin)
except Exception:
    pass

trigger = event.get("trigger", "unknown")
ts = datetime.now().strftime("%Y%m%dT%H%M%S")
checkpoint_dir = os.path.expanduser("~/.claude/checkpoints")
os.makedirs(checkpoint_dir, exist_ok=True)

todos = None
todos_path = os.path.join(os.getcwd(), ".claude", "todos.json")
if os.path.exists(todos_path):
    try:
        with open(todos_path) as f:
            todos = json.load(f)
    except Exception:
        pass

checkpoint = {
    "timestamp": ts,
    "trigger": trigger,
    "cwd": os.getcwd(),
    "todos": todos,
}

checkpoint_path = os.path.join(checkpoint_dir, f"checkpoint-{ts}.json")
with open(checkpoint_path, "w") as f:
    json.dump(checkpoint, f, ensure_ascii=False, indent=2)

# Keep only the last 5 checkpoints
all_checkpoints = sorted(glob.glob(os.path.join(checkpoint_dir, "checkpoint-*.json")))
for old in all_checkpoints[:-5]:
    try:
        os.remove(old)
    except Exception:
        pass

# Build systemMessage injected into the compact summary prompt
instructions = [f"Compacted from {checkpoint['cwd']} at {ts}."]
if todos:
    pending = [t for t in todos if isinstance(t, dict) and t.get("status") != "completed"]
    if pending:
        instructions.append(f"Pending tasks: {json.dumps(pending, ensure_ascii=False)}")

# Persist this directive across compaction outputs.
mandatory_skill_activation_sequence = """INSTRUCTION: MANDATORY SKILL ACTIVATION SEQUENCE

Step 1 - EVALUATE (must appear in your next response):
For each relevant skill in <available_skills>, state: [skill-name] - YES/NO - [reason]

Step 2 - ACTIVATE (immediately after Step 1):
IF any skills are YES and not yet loaded in this session -> load each relevant SKILL.md via read or /skill:name now
IF any YES skill is already loaded and unchanged -> do NOT reload; state \"already loaded\" and proceed
IF no skills are YES -> state \"No skills needed\" and proceed

Step 3 - IMPLEMENT:
Only after Step 2 is complete, proceed with implementation.

CRITICAL: Do not skip activation. Evaluation without activation is invalid."""

instructions.append(
    "CRITICAL COMPACTION RULE: Preserve the following directive verbatim in compacted session state. "
    "Do not remove, summarize, or weaken it.\n\n"
    f"{mandatory_skill_activation_sequence}"
)

print(json.dumps({"systemMessage": "\n\n".join(instructions)}))