{
  inputs = {
    # Principle inputs (updated by `nix run .#update`)
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nix-darwin.url = "github:lnl7/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    flake-parts.url = "github:hercules-ci/flake-parts";
    nixos-flake.url = "github:srid/nixos-flake";

    treefmt-nix.url = "github:numtide/treefmt-nix";

    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    agenix.url = "github:ryantm/agenix";

    mac-app-util.url = "github:hraban/mac-app-util";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    emacs-lsp-booster = {
      url = "github:slotThe/emacs-lsp-booster-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = inputs@{ self, ... }:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];
      imports = [
        inputs.treefmt-nix.flakeModule
        inputs.nixos-flake.flakeModule
        ./users
        ./home
        ./share
        ./templates
      ];

      flake = {
        darwinConfigurations.iinjaeui-MacBookPro =
          self.nixos-flake.lib.mkMacosSystem
            ./systems/darwin;

        nixosConfigurations.wsl =
          self.nixos-flake.lib.mkLinuxSystem
            ./systems/nixos;
      };

      perSystem = { self', pkgs, lib, config, ... }: {
        # Flake inputs we want to update periodically
        # Run: `nix run .#update`.
        nixos-flake.primary-inputs = [
          "nixpkgs"
          "home-manager"
          "nix-darwin"
          "nixos-flake"
          "nix-index-database"
          "rust-overlay"
          "emacs-lsp-booster"
        ];

        treefmt.config = {
          projectRootFile = "flake.nix";
          programs.nixpkgs-fmt.enable = true;
        };
        formatter = config.treefmt.build.wrapper;

        packages.default = self'.packages.activate;
        devShells.default = pkgs.mkShell {
          inputsFrom = [ config.treefmt.build.devShell ];
          packages = with pkgs; [
            just
            # colmena
          ];
        };
      };
    };
}
