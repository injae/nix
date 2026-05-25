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

  local.ollama.enable = false;

  local.llama-cpp = {
    enable = true;
    modelsDir = "/Users/${flake.config.people.myself}/.local/share/llama-cpp/models";
    models = [
      {
        name = "qwen3-coder";
        filename = "qwen3-coder-30b-q4_k_xl.gguf";
        url = "https://huggingface.co/unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF/resolve/main/Qwen3-Coder-30B-A3B-Instruct-UD-Q4_K_XL.gguf";
      }
    ];
    serve = "qwen3-coder";
    gpuLayers = 99;
    ctxSize = 32768;
  };

  # Enable touch id for sudo
  security.pam.services.sudo_local = {
    enable = true;
    touchIdAuth = true;
    watchIdAuth = true;
    reattach = true;
  };
}
