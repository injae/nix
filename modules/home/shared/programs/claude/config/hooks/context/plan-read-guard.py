#!/usr/bin/env python3
"""Deny a plan or exploration write that cites code its author never read.

`record` (PostToolUse) logs the line ranges each read tool showed, per session and per subagent;
`check` (PreToolUse) compares a plan or explore-file write against that log. Plans kept being
written from memory, and exploration tables from grep-block headers, while every written rule said
"read first"; a rule without a check is not kept.
"""

import json
import os
import re
import sys
import tempfile
import time
from pathlib import Path

LOG_DIR = Path(os.environ.get("PLAN_GUARD_LOG_DIR", Path(tempfile.gettempdir()) / "claude-plan-read-guard"))

PLAN_FILE = re.compile(r"(?:^|[-_/])plan(?:-v?\d+)?(?:\.affected)?\.md$")
AGENT_NOTE = re.compile(r"\.claude/tmp/[^/]*\.md$")
REVIEW_FILE = re.compile(r"codex-review-[^/]*-r\d+\.md$")
CITATION = re.compile(r"(?<![\w/.:-])((?:[\w.-]+/)*[\w.-]+\.[A-Za-z]\w*):(\d+)(?:-(\d+))?")
GUESS = re.compile(
    r"추정|기억으로|기억상|확인 못|확인하지 못|미확인|확인 필요|검증되지 않|확인 후 확정|가정한다|예상(?! ?(?:결과|값|출력))"
    r"|\bTBD\b|unverified|not verified|\bassum(?:e|ed|ing)\b|아마도?|probably|presumably",
    re.I)
TEST_ANSWER = re.compile(r"(?:시험|test)\s*[:：]?\s*`[\w:]+`", re.I)
BASH_PLAN_WRITE = re.compile(r"(?:sed\s+-i|>>?|\btee\b)[^|;&]*?\S*plan[^\s/]*\.md")

WHOLE_FILE = (1, 10**9)
READ_DEFAULT_LIMIT = 2000
MAX_LISTED = 15

SED_RANGE = re.compile(r"sed\s+-n\s+['\"]?(\d+)(?:,(\d+))?p['\"]?\s+([^\s;|&]+)")
AWK_RANGE = re.compile(r"awk\s+'NR\s*>=\s*(\d+)\s*&&\s*NR\s*<=\s*(\d+)[^']*'\s+([^\s;|&]+)")
HEAD_RANGE = re.compile(r"head\s+-(?:n\s*)?(\d+)\s+([^\s;|&]+)")
CAT_FILES = re.compile(r"\bcat\s+((?:[^\s;|&<>]+\s*)+)")
CD_DIR = re.compile(r"(?:^|&&|;)\s*cd\s+([^\s;&|]+)")
SHOWN_LINE = re.compile(r"^\s+(?:▶\s+)?(\d+)\s")
DECL_HEADER = re.compile(r"^\s+\S.*\s\[(\d+)-\d+\]\s*$")
GREP_HIT = re.compile(r"^([^\s:]+\.[A-Za-z]\w*)[:-](\d+)[:-]", re.MULTILINE)
DEF_LOCATION = re.compile(r"(/[^\s:]+):(\d+)")


# ---------- shared ----------

def response_text(resp) -> str:
    if isinstance(resp, str):
        return resp
    if isinstance(resp, list):
        return "\n".join(response_text(r) for r in resp)
    if isinstance(resp, dict):
        return "\n".join(response_text(v) for v in resp.values())
    return ""


def resolve(path: str, base: str) -> str:
    return os.path.normpath(os.path.join(base, os.path.expanduser(path)))


def log_path(event: dict) -> Path:
    # A subagent's reads reach its caller only as a summary, so each reader keeps its own log.
    agent = event.get("agent_id")
    return LOG_DIR / (f"{event['session_id']}-{agent}.jsonl" if agent else f"{event['session_id']}.jsonl")


def load_reads(event: dict) -> list[dict]:
    path = log_path(event)
    if not path.exists():
        return []
    with path.open() as f:
        return [json.loads(line) for line in f if line.strip()]


# ---------- record ----------

def reads_of_read(inp: dict) -> list[tuple[str, int, int]]:
    start = inp.get("offset") or 1
    limit = inp.get("limit") or READ_DEFAULT_LIMIT
    return [(inp["file_path"], start, start + limit - 1)]


def reads_of_symbol_source(inp: dict, text: str) -> list[tuple[str, int, int]]:
    line = int(inp["line"])
    return [(inp["file_path"], line, line + text.count("\n") + 1)]


def reads_of_def_source(text: str) -> list[tuple[str, int, int]]:
    match = DEF_LOCATION.search(text)
    if not match:
        return []
    line = int(match.group(2))
    return [(match.group(1), line, line + text.count("\n") + 1)]


def reads_of_grep_block(inp: dict, text: str) -> list[tuple[str, int, int]]:
    # Headers mode shows locations only; it is a survey, not a read.
    if inp.get("headers"):
        return []
    root = inp.get("path") or "."
    single_file = os.path.isfile(root)
    reads, current = [], root if single_file else None
    for line in text.splitlines():
        if line and not line[0].isspace() and not line[0].isdigit():
            current = root if single_file else os.path.join(root, line.strip())
            continue
        shown = SHOWN_LINE.match(line) or DECL_HEADER.match(line)
        if shown and current:
            n = int(shown.group(1))
            reads.append((current, n, n))
    return reads


def reads_of_bash(command: str, text: str, cwd: str) -> list[tuple[str, int, int]]:
    cd = CD_DIR.search(command)
    base = resolve(cd.group(1), cwd) if cd else cwd
    reads = [(resolve(f, base), int(n), int(n)) for f, n in GREP_HIT.findall(text)]
    for a, b, f in SED_RANGE.findall(command):
        reads.append((resolve(f, base), int(a), int(b or a)))
    for a, b, f in AWK_RANGE.findall(command):
        reads.append((resolve(f, base), int(a), int(b)))
    for n, f in HEAD_RANGE.findall(command):
        reads.append((resolve(f, base), 1, int(n)))
    for group in CAT_FILES.findall(command):
        for f in group.split():
            if not f.startswith("-"):
                reads.append((resolve(f, base), *WHOLE_FILE))
    return reads


def reads_of(tool: str, inp: dict, text: str, cwd: str) -> list[tuple[str, int, int]]:
    if tool == "Read":
        return reads_of_read(inp)
    if tool.endswith("__symbol-source"):
        return reads_of_symbol_source(inp, text)
    if tool.endswith("__def-source"):
        return reads_of_def_source(text)
    if tool.endswith("__grep-block"):
        return reads_of_grep_block(inp, text)
    if tool == "Bash":
        return reads_of_bash(inp.get("command", ""), text, cwd)
    if tool == "Grep":
        return [(f, int(n), int(n)) for f, n in GREP_HIT.findall(text)]
    return []


def record(event: dict) -> None:
    tool, inp = event.get("tool_name", ""), event.get("tool_input") or {}
    cwd = event.get("cwd") or os.getcwd()
    reads = reads_of(tool, inp, response_text(event.get("tool_response")), cwd)
    if not reads:
        return
    LOG_DIR.mkdir(parents=True, exist_ok=True)
    now = time.time_ns()
    with log_path(event).open("a") as f:
        for path, start, end in reads:
            f.write(json.dumps({"t": now, "path": resolve(path, cwd), "start": start, "end": end}) + "\n")


# ---------- check ----------

def same_file(read_path: str, cited: str) -> bool:
    if "/.../" in cited:
        head, tail = cited.split("/.../", 1)
        return f"/{head}/" in read_path and read_path.endswith("/" + tail)
    if "/" in cited:
        return read_path.endswith("/" + cited) or read_path == cited
    return os.path.basename(read_path) == cited


def covered(reads: list[dict], cited: str, start: int, end: int) -> bool:
    spans = sorted((r["start"], r["end"]) for r in reads if same_file(r["path"], cited))
    reach = start - 1
    for a, b in spans:
        if a > reach + 1:
            break
        reach = max(reach, b)
        if reach >= end:
            return True
    return reach >= end


def citations(text: str) -> list[tuple[str, int, int]]:
    out = []
    for path, a, b in CITATION.findall(text):
        if PLAN_FILE.search(path) or REVIEW_FILE.search(path):
            continue
        out.append((path, int(a), int(b or a)))
    return out


def unread_citations(text: str, reads: list[dict]) -> list[str]:
    return [f"`{p}:{a}-{b}` — not shown to you; open those lines"
            for p, a, b in dict.fromkeys(citations(text)) if not covered(reads, p, a, b)]


def guesses(text: str) -> list[str]:
    return [f"guess: \"{line.strip()[:120]}\" — answer it with a tool, name the test that settles it (시험: `name`), or drop it"
            for line in text.splitlines() if GUESS.search(line) and not TEST_ANSWER.search(line)]


def unread_review_citations(reads: list[dict]) -> list[str]:
    reviews = [r for r in reads if REVIEW_FILE.search(r["path"])]
    if not reviews:
        return []
    latest = max(reviews, key=lambda r: r["t"])
    try:
        review_text = Path(latest["path"]).read_text()
    except OSError:
        return []
    name = os.path.basename(latest["path"])
    return [f"`{p}:{a}-{b}` — cited by {name}, never opened"
            for p, a, b in dict.fromkeys(citations(review_text))
            if not covered(reads, p, a, b)]


def marked_unverified(line: str) -> bool:
    return line.rstrip(" |`*").endswith("?")


def written_text(tool: str, inp: dict) -> str | None:
    if tool == "Write":
        return inp.get("content", "")
    if tool == "Edit":
        return inp.get("new_string", "")
    if tool == "MultiEdit":
        return "\n".join(e.get("new_string", "") for e in inp.get("edits", []))
    return None


def plan_problems(text: str, event: dict) -> list[str]:
    reads = load_reads(event)
    return unread_citations(text, reads) + guesses(text) + unread_review_citations(reads)


def explore_problems(text: str, event: dict) -> list[str]:
    claimed = "\n".join(line for line in text.splitlines() if not marked_unverified(line))
    return unread_citations(claimed, load_reads(event))


def problems(event: dict) -> tuple[str, list[str]]:
    tool, inp = event.get("tool_name", ""), event.get("tool_input") or {}
    if tool == "Bash" and BASH_PLAN_WRITE.search(inp.get("command", "")):
        return "plan", ["plan edited through the shell — use Edit or Write so the plan can be checked"]
    text = written_text(tool, inp)
    target = inp.get("file_path", "")
    if text is None:
        return "", []
    if PLAN_FILE.search(target):
        return "plan", plan_problems(text, event)
    if event.get("agent_id") and AGENT_NOTE.search(target):
        return "explore", explore_problems(text, event)
    return "", []


HEADLINE = {
    "plan": "Plan cites or claims code this session has not read. Read it, then write again — "
            "no approval needed for reading:\n",
    "explore": "Exploration file cites lines you never saw — grep-block headers, graft locations and other "
               "explore files show where code is, not what it does. Open each (grep-block without headers, "
               "symbol-source or Read), or end its row with `?`:\n",
}


def deny(kind: str, found: list[str]) -> dict:
    listed = "\n".join(f"- {p}" for p in found[:MAX_LISTED])
    more = f"\n- … {len(found) - MAX_LISTED} more" if len(found) > MAX_LISTED else ""
    return {"hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "deny",
        "permissionDecisionReason": HEADLINE[kind] + listed + more,
    }}


def check(event: dict) -> dict | None:
    kind, found = problems(event)
    return deny(kind, found) if found else None


def main() -> None:
    try:
        event = json.load(sys.stdin)
    except json.JSONDecodeError:
        sys.exit(0)
    if sys.argv[1:] == ["record"]:
        record(event)
    elif sys.argv[1:] == ["check"]:
        decision = check(event)
        if decision:
            print(json.dumps(decision, ensure_ascii=False))


if __name__ == "__main__":
    main()
