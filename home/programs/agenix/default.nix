{ flake, lib, options, pkgs, ... }:
let
  user = flake.config.people.myself;
  home-dir =
    if pkgs.stdenv.hostPlatform.isDarwin
    then "/Users/${user}" else "/home/${user}";
in
{
  home.packages = with pkgs; [
    age
    gnupg
    ssh-to-pgp
    ssh-to-age
  ];

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
