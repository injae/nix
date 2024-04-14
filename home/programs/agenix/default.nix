{ flake, lib, options, pkgs, config, ... }:

let
  user = flake.config.people.myself;
  home-dir =
    if pkgs.stdenv.hostPlatform.isDarwin
    then "/Users/${user}" else "/home/${user}";
in
{
  age =
    {
      secrets =
        let
          toName = lib.removeSuffix ".age";
          toSecret = name: { ... }: {
            file = ./. + "/${name}";
          };
          convertSecrets = n: v: lib.nameValuePair (toName n) (toSecret n v);
          secrets = import ./secrets.nix;
        in
        lib.mapAttrs' convertSecrets secrets;
      identityPaths = options.age.identityPaths.default ++ [
        "${home-dir}/.ssh/id_ed25519"
      ];
    };
}
