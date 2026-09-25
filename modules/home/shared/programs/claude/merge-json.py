import json
import os
from pathlib import Path
import sys
import tempfile


def merge(current, managed):
    for key, value in managed.items():
        if isinstance(value, dict) and isinstance(current.get(key), dict):
            merge(current[key], value)
        else:
            current[key] = value


target = Path(sys.argv[1]).expanduser()
target.parent.mkdir(parents=True, exist_ok=True)
current = json.loads(target.read_text()) if target.exists() else {}
managed = json.loads(Path(sys.argv[2]).read_text())
merge(current, managed)

# os.replace swaps out the old store symlink rather than writing through it.
with tempfile.NamedTemporaryFile("w", dir=target.parent, delete=False) as output:
    json.dump(current, output, indent=2)
    temporary = output.name
os.replace(temporary, target)
