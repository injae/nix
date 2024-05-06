{
  description = "A basic gomod2nix flake with a shell";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    gomod-nix = {
      url = "github:nix-community/gomod2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { nixpkgs, flake-utils, gomod-nix, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ gomod-nix.overlays.default ];
        };
      in
      {
        packages = rec {
          example = with pkgs; buildGoApplication {
            pname = "example";
            version = "0.1.0";
            src = ./.;
            modules = ./gomod2nix.toml;
            subPackages = [ "cmd/example" ];
            nativeBuildInputs = [ ];
            buildInputs = [ ];
            preBuild = '''';
            meta = with lib; {
              description = "";
              homepage = "";
              license = licenses.mit;
              maintainers = with maintainers; [ injae ];
            };
          };
          default = example;
        };
        devShells.default = with pkgs; mkShell {
          packages = [
            nixfmt-rfc-style
            gomod2nix

            go
            gopls
            golangci-lint
            gotools
            delve
          ];
          buildInputs = [ ];
          shellHook = ''gomod2nix generate'';
        };
      });
}
