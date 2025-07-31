{
  pkgs,
  flake,
  ...
}:
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
    inputs.sops-nix.nixosModules.sops
  ];
  nixpkgs.hostPlatform = "x86_64-linux";
  nixpkgs.overlays = [
    (self: super: {
      docker = super.docker.override { iptables = pkgs.iptables-legacy; };
    })
  ];
  system.stateVersion = "25.05";
  wsl = {
    enable = true;
    defaultUser = user;
    startMenuLaunchers = true;
    wslConf = {
      interop = {
        appendWindowsPath = false;
      };
      experimental = {
        networkingMode = "mirrored";
        dnsTunneling = true;
      };
    };
  };
  boot.tmp.cleanOnBoot = true;
  #boot.binfmt = {
  #  emulatedSystems = [ "aarch64-linux" ];
  #  preferStaticEmulators = true;
  #};

  # docker setting
  virtualisation.docker.enable = true;
  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;
  };

  programs.zsh.enable = true;
  programs.nix-ld = {
    enable = true;
    package = pkgs.nix-ld-rs;
  };

  services.passSecretService.enable = true;
  environment.systemPackages = with pkgs; [
    pass-secret-service
    gccStdenv
    wslu
    xdg-utils
  ];
  services.dbus.packages = [ pkgs.pass-secret-service ];

  environment.variables.NODE_TLS_REJECT_UNAUTHORIZED = "0";

  security = {
    sudo.enable = true;
    pki.certificateFiles = [ ];
  };
}
