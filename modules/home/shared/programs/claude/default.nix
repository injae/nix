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

  home.file.".claude/skills/archify".source = pkgs.archify-skill;

  home.file.".claude/skills/vercel-composition-patterns".source =
    "${pkgs.vercel-agent-skills}/vercel-composition-patterns";
  home.file.".claude/skills/vercel-react-best-practices".source =
    "${pkgs.vercel-agent-skills}/vercel-react-best-practices";
  home.file.".claude/skills/vercel-react-view-transitions".source =
    "${pkgs.vercel-agent-skills}/vercel-react-view-transitions";
  home.file.".claude/skills/web-design-guidelines".source =
    "${pkgs.vercel-agent-skills}/web-design-guidelines";

  # Claude Code auto-loads a plugin tree under ~/.claude/skills as
  # <name>@skills-dir, so the marketplace install is replaced by a pinned
  # derivation.
  home.file.".claude/skills/superpowers".source = pkgs.superpowers-plugin;
  home.file.".claude/skills/caveman".source = pkgs.caveman-plugin;
  home.file.".claude/skills/codex".source = pkgs.codex-plugin;

  home.activation.claudeMcpServers = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${pkgs.python3}/bin/python3 ${mergeMcpServers}
  '';
}
