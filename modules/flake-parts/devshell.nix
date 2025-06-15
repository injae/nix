{ ... }:
{
  imports = [ ];
  perSystem =
    {
      inputs',
      config,
      pkgs,
      ...
    }:
    {
      devShells.default = pkgs.mkShell {
        inputsFrom = [ config.treefmt.build.devShell ];
        packages = with pkgs; [
          just
          nixfmt-rfc-style
        ];
      };
    };
}
