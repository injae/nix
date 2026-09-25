{ lib, pkgs }:
{
  model = "gpt-6-sol";
  model_reasoning_effort = "high";
  sandbox_workspace_write.network_access = true;
  mcp_servers = {
    "emacs-tools" = {
      command = "sh";
      args = [
        "-c"
        ''exec python3 "$HOME/.claude/scripts/emacs-mcp-bridge.py"''
      ];
    };
    graft = {
      command = lib.getExe pkgs.graft;
      args = [ "mcp" ];
    };
  };
}
