{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
let
  cfg = config.local.ollama;
  inherit (pkgs) ollama;
in
{
  options = {
    local.ollama = {
      enable = mkOption {
        description = "Enable ollama service";
        default = false;
        type = types.bool;
      };

      ollamaHost = mkOption {
        description = "The host address for the ollama service";
        default = "127.0.0.1:11434";
        type = types.str;
      };
    };
  };

  config = mkIf cfg.enable ({
    # https://github.com/LnL7/nix-darwin/pull/972/files
    environment.systemPackages = [ ollama ];
    launchd.user.agents.ollama = {
      path = [ config.environment.systemPath ];
      serviceConfig = {
        KeepAlive = true;
        RunAtLoad = true;
        ProgramArguments = [
          "${ollama}/bin/ollama"
          "serve"
        ];
        EnvironmentVariables = {
          OLLAMA_HOST = cfg.ollamaHost;
        };
      };
    };
  });

}
