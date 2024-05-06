{
  description = "A basic go flake with a shell";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ ];
        };
      in
      {
        packages = rec {
          example = with pkgs; buildGoModule {
            pname = "example";
            version = "0.1.0";
            src = lib.cleanSource ./.;
            subPackages = [ "cmd/example" ];
            vendorHash = lib.fakeHash;
            NativeBuildInputs = [ ];
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

            go
            gopls
            golangci-lint
            gotools
            delve
          ];
          buildInputs = [ ];
          shellHook = '''';
        };
      });
}
