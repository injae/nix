import os
from pathlib import Path
import sys
import tempfile

import tomlkit
from tomlkit.items import InlineTable, Table


def merge(current, managed):
    for key, value in managed.items():
        if isinstance(value, (Table, InlineTable)) and isinstance(
            current.get(key), (Table, InlineTable)
        ):
            merge(current[key], value)
        else:
            current[key] = value


target = Path.home() / ".codex" / "config.toml"
target.parent.mkdir(parents=True, exist_ok=True)
current = tomlkit.parse(target.read_text()) if target.exists() else tomlkit.document()
managed = tomlkit.parse(Path(sys.argv[1]).read_text())
merge(current, managed)

with tempfile.NamedTemporaryFile("w", dir=target.parent, delete=False) as output:
    output.write(tomlkit.dumps(current))
    temporary = output.name
os.replace(temporary, target)
