{ lib, pkgs }:
{
  model = "gpt-6.1-sol";
  model_reasoning_effort = "medium";
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
