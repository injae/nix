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

print(json.dumps({"systemMessage": " ".join(instructions)}))