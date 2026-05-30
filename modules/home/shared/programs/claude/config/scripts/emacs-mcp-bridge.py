#!/usr/bin/env python3
"""stdio ↔ HTTP bridge for Emacs MCP server.

Used when running claude outside Emacs. Ensures Emacs daemon is running,
acquires the MCP HTTP server port via emacsclient, then bridges MCP
stdio JSON-RPC to the Emacs HTTP endpoint.
"""

import json
import subprocess
import sys
import time
import urllib.error
import urllib.request
from typing import Any

MAX_RETRIES = 3
DAEMON_WAIT_SECS = 5.0
HTTP_TIMEOUT_SECS = 30


def _emacsclient_eval(expr: str) -> str:
    result = subprocess.run(
        ["emacsclient", "--eval", expr],
        capture_output=True,
        text=True,
        timeout=10,
    )
    if result.returncode != 0:
        raise RuntimeError(result.stderr.strip())
    return result.stdout.strip()


def _get_mcp_port() -> int | None:
    try:
        output = _emacsclient_eval("(progn (require 'claude-code-ide nil t) (claude-code-ide-mcp-server-ensure-server))")
        port = int(output)
        return port if port > 0 else None
    except (ValueError, RuntimeError, subprocess.TimeoutExpired):
        return None


def _start_emacs_daemon() -> None:
    subprocess.Popen(
        ["emacs", "--daemon"],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    time.sleep(DAEMON_WAIT_SECS)


def acquire_port() -> int:
    for attempt in range(MAX_RETRIES):
        port = _get_mcp_port()
        if port is not None:
            return port
        if attempt == 0:
            _start_emacs_daemon()
        else:
            time.sleep(2.0)
    raise RuntimeError(
        "Cannot acquire Emacs MCP server port after retries. "
        "Ensure emacs --daemon is running with claude-code-ide loaded."
    )


def _post_mcp(url: str, body: dict[str, Any]) -> dict[str, Any] | None:
    data = json.dumps(body).encode()
    req = urllib.request.Request(
        url,
        data=data,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=HTTP_TIMEOUT_SECS) as resp:
        if resp.status == 204:
            return None
        content = resp.read()
        if not content:
            return None
        return json.loads(content)


def _error_response(req_id: Any, code: int, message: str) -> dict[str, Any]:
    return {"jsonrpc": "2.0", "id": req_id, "error": {"code": code, "message": message}}


def bridge() -> None:
    port: int | None = None
    for raw in sys.stdin:
        raw = raw.strip()
        if not raw:
            continue

        req_id = None
        try:
            request = json.loads(raw)
            req_id = request.get("id")

            if port is None:
                port = acquire_port()

            response = _post_mcp(f"http://localhost:{port}/mcp", request)
            if response is not None:
                print(json.dumps(response), flush=True)

        except json.JSONDecodeError as exc:
            print(json.dumps(_error_response(req_id, -32700, f"Parse error: {exc}")), flush=True)
        except RuntimeError as exc:
            print(json.dumps(_error_response(req_id, -32603, str(exc))), flush=True)
        except urllib.error.URLError as exc:
            port = None  # reset so next request re-acquires (handles Emacs restart)
            print(json.dumps(_error_response(req_id, -32603, f"Emacs unreachable: {exc}")), flush=True)
        except Exception as exc:
            print(json.dumps(_error_response(req_id, -32603, str(exc))), flush=True)


def main() -> None:
    bridge()


if __name__ == "__main__":
    main()