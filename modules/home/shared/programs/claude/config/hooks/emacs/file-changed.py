#!/usr/bin/env python3
"""PostToolUse hook: tell Emacs that a file changed on disk.

Claude edits files through the filesystem, which leaves Emacs and its
language servers behind. eglot suppresses its own
workspace/didChangeWatchedFiles for any file a buffer visits, and
eglot--watch-globs unregisters the whole watch group once
eglot-max-file-watches is reached, so a server can keep serving pre-edit
text indefinitely. Handing the path to claude-code-ide-mcp-file-changed
reverts the buffer or notifies the servers directly.

Failure is silent: a missing or busy Emacs must never break an edit.
"""

import json
import subprocess
import sys

TIMEOUT_SECS = 5


def main() -> None:
    try:
        event = json.load(sys.stdin)
    except Exception:
        return

    path = (event.get("tool_input") or {}).get("file_path")
    if not path:
        return

    # json.dumps yields a string literal Emacs Lisp reads the same way.
    expr = f"(claude-code-ide-mcp-file-changed {json.dumps(path)})"
    try:
        subprocess.run(
            ["emacsclient", "--eval", expr],
            capture_output=True,
            timeout=TIMEOUT_SECS,
        )
    except Exception:
        pass


if __name__ == "__main__":
    main()
