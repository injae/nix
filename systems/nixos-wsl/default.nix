{ pkgs, flake, config, ... }:
let
  inherit (flake) inputs;
  inherit (inputs) self;
  user = flake.config.people.myself;
in
{
  imports = [
    # https://nix-community.github.io/NixOS-WSL/options.html
    inputs.nixos-wsl.nixosModules.default
    self.nixosModules.default
  ];
  nixpkgs.hostPlatform = "x86_64-linux";
  system.stateVersion = "24.05";
  wsl.enable = true;
  wsl.defaultUser = user;
  wsl.startMenuLaunchers = true;

  boot.tmp.cleanOnBoot = true;

  programs.zsh.enable = true;

  environment.systemPackages = with pkgs; [
    emacs-pgtk
    wslu
  ];
  services.emacs.enable = true;

  users.users.${user} = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = [ "wheel" "networkmanager" "docker" ];
  };

  security.sudo.enable = true;
}
