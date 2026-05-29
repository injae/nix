#!/usr/bin/env python3
"""Check parenthesis balance in an Emacs Lisp file.

Usage: elisp-check-parens.py <file>
Exit 0 + prints "balanced", or exit 1 + prints error with location.
"""
import sys


def check_parens(path: str) -> str:
    with open(path, encoding="utf-8") as f:
        content = f.read()

    depth = 0
    in_string = False
    escape = False
    stack: list[tuple[int, int]] = []  # (line, col) for each unmatched '('
    line = 1
    col = 0
    i = 0

    while i < len(content):
        c = content[i]

        if c == "\n":
            line += 1
            col = 0
            escape = False
            i += 1
            continue

        col += 1

        if escape:
            escape = False
            i += 1
            continue

        if in_string:
            if c == "\\":
                escape = True
            elif c == '"':
                in_string = False
        elif c == ";":
            while i < len(content) and content[i] != "\n":
                i += 1
            continue
        elif c == '"':
            in_string = True
        elif c == "(":
            stack.append((line, col))
            depth += 1
        elif c == ")":
            if depth == 0:
                return f"Unmatched ')' at line {line}, column {col}"
            stack.pop()
            depth -= 1

        i += 1

    if in_string:
        return 'Unmatched \'"\' (unclosed string)'

    if depth > 0:
        open_line, open_col = stack[-1]
        return f"Unmatched '(' at line {open_line}, column {open_col}"

    return "balanced"


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: elisp-check-parens.py <file>", file=sys.stderr)
        sys.exit(1)

    result = check_parens(sys.argv[1])
    print(result)
    sys.exit(0 if result == "balanced" else 1)