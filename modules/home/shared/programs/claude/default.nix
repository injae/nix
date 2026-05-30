{ lib, pkgs, ... }:
let
  mergeMcpServers = pkgs.writeScript "claude-merge-mcp-servers.py" ''
    import json, os

    path = os.path.expanduser("~/.claude.json")
    d = json.load(open(path)) if os.path.exists(path) else {}
    d.setdefault("mcpServers", {})["emacs-tools"] = {
        "type": "stdio",
        "command": "sh",
        "args": ["-c", "exec python3 \"$HOME/.claude/scripts/emacs-mcp-bridge.py\""],
        "env": {}
    }
    json.dump(d, open(path, "w"), indent=2)
  '';
in
{
  home.file.".claude" = {
    source = ./config;
    recursive = true;
  };

  home.activation.claudeMcpServers = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${pkgs.python3}/bin/python3 ${mergeMcpServers}
  '';
}
