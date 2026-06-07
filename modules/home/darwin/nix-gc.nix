{ pkgs, config, ... }:
{
  launchd.agents.home-manager-gc = {
    enable = true;
    config = {
      ProgramArguments = [
        "${pkgs.nix}/bin/nix-env"
        "--profile"
        "${config.home.homeDirectory}/.local/state/nix/profiles/home-manager"
        "--delete-generations"
        "7d"
      ];
      StartCalendarInterval = [
        {
          Hour = 13;
          Minute = 5;
        }
      ];
    };
  };
}