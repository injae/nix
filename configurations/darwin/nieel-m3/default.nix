{
  pkgs,
  flake,
  ...
}:
let
  inherit (flake) inputs;
  inherit (inputs) self;
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
    package = pkgs.darwin.linux-builder;
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

  local.ollama = {
    enable = true;
    environmentVariables.OLLAMA_KEEP_ALIVE = "-1";
    modelFiles.qwen3-coder = ''
      FROM SimonPu/Qwen3-Coder:30B-Instruct_Q4_K_XL

      PARAMETER num_ctx 32768
      PARAMETER temperature 0.7
      PARAMETER top_p 0.8
      PARAMETER top_k 20
      PARAMETER repeat_penalty 1.05
    '';
    preloadModels = [ "qwen3-coder" ];
  };

  # Enable touch id for sudo
  security.pam.services.sudo_local = {
    enable = true;
    touchIdAuth = true;
    watchIdAuth = true;
    reattach = true;
  };
}
