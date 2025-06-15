{
  pkgs,
  flake,
  lib,
  ...
}:
let
  mac-app-util = flake.inputs.mac-app-util.packages.${pkgs.stdenv.system}.default;
  exclude = [ "default.nix" ];
in
{
  imports = (
    with builtins;
    map (fn: ./darwin/${fn}) (filter (fn: !(elem fn exclude)) (attrNames (readDir ./darwin)))
  );
  home.activation = {
    trampolineApps = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      fromDir="$HOME/Applications/Home Manager Apps"
      toDir="$HOME/Applications/Home Manager Trampolines"
      ${mac-app-util}/bin/mac-app-util sync-trampolines "$fromDir" "$toDir"
    '';
  };
  local.colima = {
    enable = true;
    customTemplates = {
      "public-ecr" = {
        provision = [
          {
            mode = "system";
            script = "update-ca-certificates";
          }
        ];
        mounts = [
          {
            location = ./public-ecr.crt;
            mountPoint = "/usr/local/share/ca-certificates/public-ecr.crt";
            writable = false;
          }
        ];
      };
    };
  };
}
