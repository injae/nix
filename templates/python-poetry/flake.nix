{
  description = "Application packaged using poetry2nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    poetry2nix = {
      url = "github:nix-community/poetry2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, poetry2nix, pre-commit-hooks }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        spkgs = self.packages.${system};
        python = pkgs.python310;
        # see https://github.com/nix-community/poetry2nix/tree/master#api
        p2nix = poetry2nix.lib.mkPoetry2Nix { inherit pkgs; };
      in
      {
        checks = {
          pre-commit-check = pre-commit-hooks.lib.${system}.run {
            src = ./.;
            hooks = {
              nixpkgs-fmt.enable = true;
              ruff.check = true;
            };
          };
        };

        packages = rec {
          app = p2nix.mkPoetryApplication { python = python; projectDir = self; preferWheels = true; };
          venv = p2nix.mkPoetryEnv { python = python; projectDir = self; preferWheels = true; };
          default = app;
        };

        devShells.default = pkgs.mkShell (
          {
            inherit (self.checks.${system}.pre-commit-check) shellHook;
            buildInputs = self.checks.${system}.pre-commit-check.enabledPackages;
            packages = with pkgs; [
              poetry
              just
            ] ++ (with spkgs; [ app venv ]);
          }
        );
      });
}
