{
  description = "A cpp flake with a shell";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    pyproject-nix = {
      url = "github:nix-community/pyproject.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        overlays = [ ];
        pkgs = import nixpkgs {
          inherit system overlays;
        };
      in
      with pkgs;
      {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            cmake
            ninja
            gnumake
            pkg-config
            vcpkg
            ccls
            clang
            ccache
          ];
          env = {
            VCPKG_DISABLE_METRICS = 1;
            VCPKG_FORCE_SYSTEM_BINARIES = 1;
          }
          // lib.optionalAttrs pkgs.stdenv.isLinux {
          };
          shellHook = '''';
        };
      }
    );
}
