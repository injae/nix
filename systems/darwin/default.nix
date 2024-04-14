{ pkgs, flake, ... }:
let
  inherit (flake) inputs;
  inherit (inputs) self;
in
{
  imports = [
    self.darwinModules.default
    ./homebrew
    ./system.nix
    ./dock
    ./dock.nix
  ];
  nixpkgs.hostPlatform = "aarch64-darwin";

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;

  users.users.${flake.config.people.myself} = {
    name = flake.config.people.myself;
    home = "/Users/${flake.config.people.myself}";
  };

  # Enable fonts dir
  fonts.fontDir.enable = true;

  # Enable touch id for sudo
  security.pam.enableSudoTouchIdAuth = true;
}
  
