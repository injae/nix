{
  pkgs,
  flake,
  ...
}:
let
  inherit (flake) inputs;
  inherit (inputs) self;
  inherit (pkgs.stdenv.hostPlatform) system;
  stable = inputs.nixpkgs-stable.legacyPackages.${system};
  exclude = [
    "default.nix"
    "dock.nix"
  ];
  home = "/Users/${flake.config.people.myself}";
in
{
  imports = [
    self.darwinModules.default
  ]
  ++ (with builtins; map (fn: ./${fn}) (filter (fn: !(elem fn exclude)) (attrNames (readDir ./.))));

  nixpkgs.hostPlatform = "aarch64-darwin";

  nix.enable = true; # Auto upgrade nix package and the daemon service.
  ids.gids.nixbld = 30000;

  users.users.${flake.config.people.myself} = {
    name = flake.config.people.myself;
    inherit home;
  };
  system.primaryUser = flake.config.people.myself;

  # for dockerTools
  nix.linux-builder = {
    enable = true;
    package = stable.darwin.linux-builder;
    ephemeral = true;
    maxJobs = 4;
    systems = [ "aarch64-linux" ];
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

  environment.variables = {
    NIX_CONFIG_DIR = "${home}/nix";
  };

  local.ollama.enable = false;

  # Enable touch id for sudo
  security.pam.services.sudo_local = {
    enable = true;
    touchIdAuth = true;
    watchIdAuth = true;
    reattach = true;
  };
}
