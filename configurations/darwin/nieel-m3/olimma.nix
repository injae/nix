{ pkgs, config, ... }:
{
  # enable ollama service
  # https://github.com/LnL7/nix-darwin/pull/972/files
  environment.systemPackages = [ pkgs.ollama ];
  launchd.user.agents.ollama = {
    path = [ config.environment.systemPath ];
    serviceConfig = {
      KeepAlive = true;
      RunAtLoad = true;
      ProgramArguments = [
        "${pkgs.ollama}/bin/ollama"
        "serve"
      ];
      EnvironmentVariables = {
        OLLAMA_HOST = "127.0.0.1:11434";
      };
    };
  };

}
