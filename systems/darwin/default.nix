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
    #./dock
    #./dock.nix
  ];
  nixpkgs.hostPlatform = "aarch64-darwin";

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;

  environment.systemPackages = with pkgs; [ ];

  users.users.${flake.config.people.myself} = {
    name = flake.config.people.myself;
    home = "/Users/${flake.config.people.myself}";
  };

  # for dockerTools
  nix.linux-builder = {
    #enable = false;
    enable = true;
    ephemeral = true;
    maxJobs = 4;
    #config = {
    #  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
    #  virtualisation = {
    #    #darwin-builder = {
    #    #  diskSize = 40 * 1024;
    #    #  memorySize = 8 * 1024;
    #    #};
    #    cores = 6;
    #  };
    #};
    #systems = [ "aarch64-linux" ];
    #supportedFeatures = ["benchmark" "big-parallel" "kvm"];
  };

  # Enable touch id for sudo
  security.pam.enableSudoTouchIdAuth = true;
}
