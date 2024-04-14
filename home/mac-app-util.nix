{ pkgs, flake, lib, ... }:
let
  mac-app-util = flake.inputs.mac-app-util.packages.${pkgs.stdenv.system}.default;
in
{
  home.activation = {
    trampolineApps =
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        fromDir="$HOME/Applications/Home Manager Apps"
        toDir="$HOME/Applications/Home Manager Trampolines"
        ${mac-app-util}/bin/mac-app-util sync-trampolines "$fromDir" "$toDir"
      '';
  };
}

