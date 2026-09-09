"""docs/map/*.md 의 표가 코드와 갈렸는지 본다.

표는 세 갈래다:
  symbols     | name | kind | file | one-line | at |  → name 이 그 file 안에 있나
  seams       | from | via  | to   |                  → 양쪽 심볼이 src/ 안에 있나
  invariants  | rule | guarded-by |                   → guarded-by 가 실제 테스트 이름인가

심볼은 백틱으로 적는다(`PlantWork`, `PlantGraphics::yield_layer`). `::` 뒤 마지막 조각으로 찾는다.

`at` 은 그 행을 확증할 때 본 **file 의 blob 해시**(`git hash-object`, 앞 12자)다. 세 상태로 갈린다:

  `?` 또는 빈 칸  탐색이 확증 못 했다 — 리뷰어가 닫는다
  해시 불일치     확증한 뒤 그 파일이 바뀌었다 — 그 커밋의 리뷰가 다시 본다
  일치            확증됐고 안 바뀌었다

축 전체에 `head:` 하나를 물리면 그 디렉터리에 커밋 하나만 나도 지도 전체가 「다시 봐라」가 되어
신호가 뭉개진다. 그래서 낡음 판정은 **행 단위**다.
"""

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else Path.cwd()
MAPS = ROOT / "docs" / "map"
SRC = ROOT / "src"

TICKED = re.compile(r"`([^`]+)`")


def cells(line: str) -> list[str]:
    return [c.strip() for c in line.strip().strip("|").split("|")]


def symbol_leaf(text: str) -> str:
    return text.split("::")[-1].strip()


def defined_in(symbol: str, path: Path) -> bool:
    if not path.exists():
        return False
    return re.search(rf"\b{re.escape(symbol)}\b", path.read_text(encoding="utf-8")) is not None


def blob_hash(path: Path) -> str | None:
    if not path.exists():
        return None
    hashed = subprocess.run(
        ["git", "-C", str(ROOT), "hash-object", str(path)],
        check=False,
        capture_output=True,
        text=True,
    )
    return hashed.stdout.strip()[:12] or None


def defined_anywhere(symbol: str) -> bool:
    found = subprocess.run(
        ["rg", "--quiet", "--word-regexp", "--", symbol, str(SRC)],
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
    unconfirmed: list[str] = []
    stale: list[str] = []

    for row in table_rows(found.get("symbols", [])):
        if len(row) < 3:
            problems.append(f"{path.name}: symbols 행의 칸이 모자란다 — {row}")
            continue
        names = TICKED.findall(row[0])
        if not names:
            problems.append(f"{path.name}: symbols 이름이 백틱이 아니다 — {row[0]}")
            continue
        target = ROOT / row[2]
        for name in names:
            if not defined_in(symbol_leaf(name), target):
                problems.append(f"{path.name}: `{name}` 이(가) {row[2]} 에 없다")
        recorded = row[4].strip("`") if len(row) > 4 else ""
        if recorded in ("", "?"):
            unconfirmed.extend(names)
        elif recorded != blob_hash(target):
            stale.extend(names)

    for row in table_rows(found.get("seams", [])):
        if len(row) < 3:
            problems.append(f"{path.name}: seams 행의 칸이 모자란다 — {row}")
            continue
        for side in (row[0], row[2]):
            for name in TICKED.findall(side):
                if not defined_anywhere(symbol_leaf(name)):
                    problems.append(f"{path.name}: 이음새 `{name}` 이(가) src/ 에 없다")

    for row in table_rows(found.get("invariants", [])):
        if len(row) < 2:
            problems.append(f"{path.name}: invariants 행의 칸이 모자란다 — {row}")
            continue
        tests = TICKED.findall(row[1])
        if not tests:
            problems.append(f"{path.name}: 지키는 테스트가 백틱이 아니다 — {row[1]}")
        for test in tests:
            if not defined_anywhere(f"fn {symbol_leaf(test)}"):
                problems.append(f"{path.name}: `{test}` 라는 테스트가 없다")

    if unconfirmed:
        print(f"── {path.name}: 미확증 {len(unconfirmed)}행 — 리뷰가 닫는다: {', '.join(unconfirmed)}")
    if stale:
        print(f"── {path.name}: 확증 뒤 파일이 바뀐 {len(stale)}행 — 다시 본다: {', '.join(stale)}")
    return problems


def main() -> int:
    maps = sorted(MAPS.glob("*.md")) if MAPS.exists() else []
    if not maps:
        print("── 지도 없음 — docs/map/ 이 비었다")
        return 0
    problems = [p for path in maps for p in check_map(path)]
    for problem in problems:
        print(problem)
    print(f"── 지도 {len(maps)}장 · 어긋남 {len(problems)}건")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
