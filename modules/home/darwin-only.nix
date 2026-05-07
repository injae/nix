{ pkgs, ... }:
let
  #mac-app-util = flake.inputs.mac-app-util.packages.${pkgs.stdenv.hostPlatform.system}.default;
  exclude = [ "default.nix" ];
  publicEcrCertDir = pkgs.runCommand "public-ecr-cert-dir" { } ''
    mkdir -p $out
    cp ${./public-ecr.crt} $out/public-ecr.crt
  '';
in
{
  imports = (
    with builtins;
    map (fn: ./darwin/${fn}) (filter (fn: !(elem fn exclude)) (attrNames (readDir ./darwin)))
  );
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
            location = "$HOME";
            writable = true;
          }
          {
            location = publicEcrCertDir;
            mountPoint = "/usr/local/share/ca-certificates";
            writable = false;
          }
        ];
      };
    };
  };
}
