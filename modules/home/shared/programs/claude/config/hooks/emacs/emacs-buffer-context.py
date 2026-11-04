#!/usr/bin/env python3
"""UserPromptSubmit hook: inject active Emacs buffer as context."""
import os
import subprocess
import re


def main():
    # Only run inside Emacs sessions
    if not (os.environ.get("INSIDE_EMACS") or os.environ.get("TERM_PROGRAM") == "emacs"):
        return

    expr = (
        "(let* ((buf (seq-find"
        "  (lambda (b)"
        "    (let ((n (buffer-name b)))"
        "      (and (buffer-file-name b)"
        "           (not (string-prefix-p \" \" n))"
        "           (not (string-match-p \"\\\\*claude-code\" n)))))"
        "  (buffer-list))))"
        " (when buf"
        "   (format \"%s\\t%s\" (buffer-name buf) (buffer-file-name buf))))"
    )
    try:
        r = subprocess.run(
            ["emacsclient", "--eval", expr],
            capture_output=True,
            text=True,
            timeout=2,
        )
        if r.returncode != 0:
            return
        out = r.stdout.strip()
        # emacsclient wraps string results in double quotes
        m = re.match(r'^"(.*)"$', out, re.DOTALL)
        if not m:
            return
        raw = m.group(1).replace("\\t", "\t").replace("\\n", "\n")
        parts = raw.split("\t", 1)
        name = parts[0]
        path = parts[1] if len(parts) > 1 else ""
        if name:
            print(f"Active Emacs buffer: {name}")
            if path:
                print(f"File path: {path}")
    except Exception:
        pass


main()
