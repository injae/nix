{
  pkgs,
  flake,
  ...
}:
let
  inherit (flake) config inputs;
  inherit (inputs) self;
  user = config.people.myself;
in
{
  #nixos-unified.sshTarget = "${user}@nixos-wsl";
  imports = [
    # https://nix-community.github.io/NixOS-WSL/options.html
    inputs.nixos-wsl.nixosModules.default
    self.nixosModules.default
    inputs.sops-nix.nixosModules.sops
  ];
  nixpkgs.hostPlatform = "x86_64-linux";
  system.stateVersion = "24.05";
  wsl = {
    enable = true;
    defaultUser = user;
    startMenuLaunchers = true;
    wslConf.interop.appendWindowsPath = false;
  };
  boot.tmp.cleanOnBoot = true;

  # docker setting
  virtualisation.docker.enable = true;
  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;
  };

  virtualisation.incus = {
    enable = true;
    preseed = { };
  };
  networking.nftables.enable = true;

  programs.zsh.enable = true;
  programs.nix-ld = {
    enable = true;
    package = pkgs.nix-ld-rs;
    #libraries = with pkgs; [ bazelisk ];
  };

  environment.systemPackages = with pkgs; [
    gccStdenv
    wslu
    xdg-utils
  ];

  environment.variables.JAVAX_NET_SSL_TRUSTSTORE =
    let
      caBundle = config.environment.etc."ssl/certs/ca-bundle.crt".source;
      p11kit = pkgs.p11-kit.overrideAttrs (oldAttrs: {
        configureFlags = [
          "--with-trust-paths=${caBundle}"
        ];
      });
    in
    derivation {
      name = "java-cacerts";
      builder = pkgs.writeShellScript "java-cacerts-builder" ''
        ${p11kit.bin}/bin/trust \
          extract \
          --format=java-cacerts \
          --purpose=server-auth \
          $out
      '';
      system = pkgs.system;
    };
  environment.variables.NODE_TLS_REJECT_UNAUTHORIZED = "0";

  security = {
    sudo.enable = true;
    pki.certificateFiles = [ ];
  };
}
