{ pkgs, flake, ... }:
let
  inherit (flake) inputs;
  inherit (inputs) self;
  user = flake.config.people.myself;
in
{
  imports = [
    inputs.nixos-wsl.nixosModules.default
    self.nixosModules.default
  ];
  nixpkgs.hostPlatform = "x86_64-linux";
  system.stateVersion = "24.05";
  wsl.enable = true;
  wsl.defaultUser = user;
  boot.tmp.cleanOnBoot = true;

  programs.zsh.enable = true;

  environment.systemPackages = with pkgs; [
    emacs-pgtk
  ];
  services.emacs.enable = true;

  users.users.${user} = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = [ "wheel" "networkmanager" "docker" ];
    #password = ""
  };

  security.sudo.enable = true;
}
  
