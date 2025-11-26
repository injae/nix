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
  exclude = [
    "default.nix"
    "dock.nix"
    "credentials.crt"
  ];
in
{
  imports = [
    self.darwinModules.default
  ]
  ++ (with builtins; map (fn: ./${fn}) (filter (fn: !(elem fn exclude)) (attrNames (readDir ./.))));

  nixpkgs.hostPlatform = "aarch64-darwin";

  nix.enable = true; # Auto upgrade nix package and the daemon service.
  ids.gids.nixbld = 350;

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

  local.ollama.enable = false;

  # Enable touch id for sudo
  security.pam.services.sudo_local.touchIdAuth = true;
  security.pam.services.sudo_local.watchIdAuth = true;
  security.pam.services.sudo_local.reattach = true;

  environment.variables =
    let
      ca-cert-path = "/etc/ssl/certs/ca-certificates.crt";
    in
    {
      NIX_SSL_CERT_FILE = ca-cert-path;
      CURL_CA_CERT_FILE = ca-cert-path;
      SSL_CERT_FILE = ca-cert-path;
      REQUEST_CA_BUNDLE = ca-cert-path;
      NODE_EXTRA_CA_CERTS = ca-cert-path;
      NODE_TLS_REJECT_UNAUTHORIZED = "0";
    };

  security = {
    pki = {
      certificateFiles = [ ./credentials.crt ];
    };
  };
}
