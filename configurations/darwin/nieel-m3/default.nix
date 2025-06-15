{
  pkgs,
  flake,
  ...
}:
let
  inherit (flake) inputs;
  inherit (inputs) self;
  system = pkgs.stdenv.system;
  stable = inputs.nixpkgs-stable.legacyPackages.${system};
in
{
  #nixos-unified.sshTarget = "${user}@nieel-m3";
  imports = [
    self.darwinModules.default
    ./homebrew
    ./system.nix
    #./olimma.nix
    #./dock
    #./dock.nix
  ];
  nixpkgs.hostPlatform = "aarch64-darwin";

  # Auto upgrade nix package and the daemon service.
  nix.enable = true;
  ids.gids.nixbld = 30000;

  users.users.${flake.config.people.myself} = {
    name = flake.config.people.myself;
    home = "/Users/${flake.config.people.myself}";
  };
  system.primaryUser = flake.config.people.myself;

  # for dockerTools
  nix.linux-builder = {
    enable = true;
    package = stable.darwin.linux-builder;
    ephemeral = true;
    maxJobs = 4;
    systems = [
      "aarch64-linux"
    ];
    config = {
      virtualisation = {
        darwin-builder = {
          diskSize = 40 * 1024;
          memorySize = 8 * 1024;
        };
        cores = 6;
      };
    };
  };

  # Enable touch id for sudo
  security.pam.services.sudo_local.touchIdAuth = true;
}
