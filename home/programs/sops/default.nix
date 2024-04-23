{ flake, pkgs, config, lib, ... }:
let
  user = flake.config.people.myself;
  home-dir =
    if pkgs.stdenv.hostPlatform.isDarwin
    then "/Users/${user}" else "/home/${user}";
in
{
  home.packages = with pkgs; [
    sops
    age
    gnupg
    ssh-to-pgp
    ssh-to-age
  ];

  sops = {
    defaultSopsFile = ./secrets/secrets.yaml;
    age.keyFile = "${home-dir}/.config/sops/age/keys.txt";
    secrets = {
      "spotify/id" = { };
      "spotify/secret" = { };
      "discord/token" = { };
      "chatgpt/api-key" = { };
    };
  };

  programs.zsh.envExtra = with config.sops;
    let
      toName = name: builtins.replaceStrings [ "/" "-" ] [ "_" "_" ] (lib.toUpper name);
      toPath = name: secrets."${name}".path;
      convertSecretEnv = name: "export ${toName name}=$(cat ${toPath name})";
      filterSecrets = name: !(lib.hasPrefix "secrets" name);
    in
    builtins.foldl' (acc: elm: acc + elm + "\n") ""
      (builtins.map convertSecretEnv (builtins.filter filterSecrets (builtins.attrNames secrets)));
}
