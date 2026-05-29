#!/usr/bin/env python3
import sys
import json
import os
import re

event = {}
try:
    event = json.load(sys.stdin)
except Exception:
    sys.exit(0)

# Runtime already prevents re-blocking when stop_hook_active=true,
# but we respect it explicitly for clarity.
if event.get("stop_hook_active"):
    sys.exit(0)

transcript_path = event.get("transcript_path", "")
if not transcript_path or not os.path.exists(transcript_path):
    sys.exit(0)

try:
    with open(transcript_path, "rb") as f:
        f.seek(0, 2)
        size = f.tell()
        f.seek(max(0, size - 8192))
        tail = f.read().decode("utf-8", errors="replace")
except Exception:
    sys.exit(0)

tokens = re.findall(r'"input_tokens"\s*:\s*(\d+)', tail)
ctx = re.findall(r'"context_window"\s*:\s*(\d+)', tail)

if not tokens:
    sys.exit(0)

context_size = int(ctx[-1]) if ctx else 200_000
usage_pct = int(tokens[-1]) / context_size * 100

if usage_pct >= 75:
    print(json.dumps({
        "decision": "block",
        "reason": f"Context at {usage_pct:.0f}% — please run /compact before stopping",
    }))