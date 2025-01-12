{
  inputs = {
    # Principle inputs (updated by `nix run .#update`)
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    nix-darwin = {
      url = "github:lnl7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    mac-app-util = {
      url = "github:hraban/mac-app-util";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-wsl = {
      url = "github:nix-community/NixOs-WSL/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lix-module = {
      url = "https://git.lix.systems/lix-project/nixos-module/archive/2.91.0.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-parts.url = "github:hercules-ci/flake-parts";
    nixos-flake.url = "github:srid/nixos-flake?rev=495b03271a03df5bcd12a572612fe6953db4424f";

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    poetry2nix = {
      url = "github:nix-community/poetry2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    emacs-overlay = {
      url = "github:nix-community/emacs-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    emacs-lsp-booster = {
      url = "github:slotThe/emacs-lsp-booster-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    #vscode-server.url = "github:nix-community/nixos-vscode-server";
  };
  outputs =
    inputs@{ self, ... }:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      imports = [
        inputs.treefmt-nix.flakeModule
        inputs.nixos-flake.flakeModule
        ./users
        ./home
        ./share
        ./templates
      ];
      flake = {
        darwinConfigurations = {
          nieel-m3 = self.nixos-flake.lib.mkMacosSystem ./systems/darwin;
        };
        nixosConfigurations = {
          nixos = self.nixos-flake.lib.mkLinuxSystem ./systems/nixos-wsl;
        };
      };

      perSystem =
        {
          self',
          pkgs,
          lib,
          config,
          ...
        }:
        {
          # Flake inputs we want to update periodically
          # Run: `nix run .#update`.
          nixos-flake.primary-inputs = [
            "nixpkgs"
            "home-manager"
            "nix-darwin"
            "nixos-flake"
            "nix-index-database"
            "rust-overlay"
            "emacs-overlay"
            "emacs-lsp-booster"
          ];

          treefmt = {
            projectRootFile = "flake.nix";
            programs = {
              nixfmt.enable = true;
            };
          };
          formatter = config.treefmt.build.wrapper;
          packages.default = self'.packages.activate;
          devShells.default = pkgs.mkShell {
            inputsFrom = [ config.treefmt.build.devShell ];
            packages = with pkgs; [
              just
            ];
          };
        };
    };
}
