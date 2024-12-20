{ pkgs, flake, config, ... }:
let
  inherit (flake) inputs;
  inherit (inputs) self;
in
{
  imports = [
    self.darwinModules.default
    ./homebrew
    ./system.nix
    #./dock
    #./dock.nix
  ];
  nixpkgs.hostPlatform = "aarch64-darwin";

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;

  users.users.${flake.config.people.myself} = {
    name = flake.config.people.myself;
    home = "/Users/${flake.config.people.myself}";
  };

  # for dockerTools
  nix.linux-builder = {
    enable = true;
    ephemeral = true;
    maxJobs = 4;
  };

  # enable ollama service
  # https://github.com/LnL7/nix-darwin/pull/972/files
  environment.systemPackages = [ pkgs.ollama ];
  launchd.user.agents.ollama = {
    path = [ config.environment.systemPath ];
    serviceConfig = {
      KeepAlive = true;
      RunAtLoad = true;
      ProgramArguments = [ "${pkgs.ollama}/bin/ollama" "serve" ];
      EnvironmentVariables = {
        OLLAMA_HOST = "127.0.0.1:11434";
      };
    };
  };

  # Enable touch id for sudo
  security.pam.enableSudoTouchIdAuth = true;
}
