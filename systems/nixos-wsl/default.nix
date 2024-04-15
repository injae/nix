{ pkgs, flake, ... }:
let
  inherit (flake) inputs;
  inherit (inputs) self;
in
{
  imports = [
    inputs.nixos-wsl.nixosModules.default
    self.nixosModules.default
  ];
  nixpkgs.hostPlatform = "x86_64-linux";
  system.stateVersion = "24.05";
  wsl.enable = true;

  environment.systemPackages = with pkgs; [ ];

  programs.zsh.enable = true;
  users.users.${flake.config.people.myself} = {
    shell = pkgs.zsh;
  };
}
  
