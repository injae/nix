{ lib, pkgs, ... }:
let
  mcpServers = (pkgs.formats.json { }).generate "claude-mcp-servers.json" {
    mcpServers = {
      emacs-tools = {
        type = "stdio";
        command = "sh";
        args = [
          "-c"
          "exec python3 \"$HOME/.claude/scripts/emacs-mcp-bridge.py\""
        ];
        env = { };
      };
      graft = {
        type = "stdio";
        command = lib.getExe pkgs.graft;
        args = [ "mcp" ];
        env = { };
      };
    };
  };
in
{
  home.packages = [ pkgs.graft ];

  home.file.".claude" = {
    source = lib.cleanSourceWith {
      src = ./config;
      filter = path: _: path != toString ./config/settings.json;
    };
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
    ${pkgs.python3}/bin/python3 ${./merge-json.py} ~/.claude.json ${mcpServers}
  '';

  # Claude Code writes runtime choices (/effort, /model) back to settings.json,
  # so it must be a real file: managed keys win, local-only keys survive.
  home.activation.claudeSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${pkgs.python3}/bin/python3 ${./merge-json.py} ~/.claude/settings.json ${./config/settings.json}
  '';
}
