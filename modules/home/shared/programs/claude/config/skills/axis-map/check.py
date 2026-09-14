"""Check whether the invariants in docs/map/*.md still name tests that exist.

One table per map:
  invariants  | rule | guarded-by |   -> is guarded-by a real test name

Test names are written in backticks (`picking_is_refused_on_a_day_the_bush_bears_nothing`). The
search uses the last segment after `::`.

Only what a checker can confirm belongs in a map. A test name can be confirmed: rename or delete
the guard and this gate turns red. Symbol lists, hand-written seams and a `head:` SHA could not
be, and are gone.
"""

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else Path.cwd()
MAPS = ROOT / "docs" / "map"
TEST_ROOTS = [ROOT / "src", ROOT / "tests"]

TICKED = re.compile(r"`([^`]+)`")


def cells(line: str) -> list[str]:
    return [c.strip() for c in line.strip().strip("|").split("|")]


def symbol_leaf(text: str) -> str:
    return text.split("::")[-1].strip()


def defined_anywhere(symbol: str) -> bool:
    roots = [str(root) for root in TEST_ROOTS if root.is_dir()]
    if not roots:
        return False
    found = subprocess.run(
        ["rg", "--quiet", "--word-regexp", "--", symbol, *roots],
        check=False,
    )
    return found.returncode == 0


def sections(text: str) -> dict[str, list[str]]:
    out: dict[str, list[str]] = {}
    current = None
    for line in text.splitlines():
        heading = re.match(r"^##\s+(\S+)", line)
        if heading:
            current = heading.group(1)
            out[current] = []
        elif current and line.startswith("|"):
            out[current].append(line)
    return out


def table_rows(lines: list[str]) -> list[list[str]]:
    rows = [cells(line) for line in lines]
    return [r for r in rows if r and not set("".join(r)) <= set("-: ")][1:]


def check_map(path: Path) -> list[str]:
    text = path.read_text(encoding="utf-8")
    problems: list[str] = []
    found = sections(text)

    for row in table_rows(found.get("invariants", [])):
        if len(row) < 2:
            problems.append(f"{path.name}: invariants row has too few cells -- {row}")
            continue
        tests = TICKED.findall(row[1])
        if not tests:
            problems.append(f"{path.name}: guarding test is not in backticks -- {row[1]}")
        for test in tests:
            if not defined_anywhere(f"fn {symbol_leaf(test)}"):
                problems.append(f"{path.name}: no test named `{test}`")

    return problems


def main() -> int:
    maps = sorted(MAPS.glob("*.md")) if MAPS.exists() else []
    if not maps:
        print("-- no maps -- docs/map/ is empty")
        return 0
    problems = [p for path in maps for p in check_map(path)]
    for problem in problems:
        print(problem)
    print(f"-- {len(maps)} maps · {len(problems)} mismatches")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
