{
  flake,
  pkgs,
  config,
  lib,
  ...
}:
let
  user = flake.config.people.myself;
  home-dir = if pkgs.stdenv.hostPlatform.isDarwin then "/Users/${user}" else "/home/${user}";
in
{
  imports = with flake.inputs; [
    sops-nix.homeManagerModules.sops
  ];

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
      "secrets/aws-credentials" = {
        path = "${home-dir}/.aws/credentials";
      };
      "secrets/wireless.env" = { };
      "secrets/NEXON.crt" = {
        path = "${home-dir}/cert/NEXON.crt";
      };
      "secrets/nexon-injae-gitlab" = { };
    };
  };

  programs.zsh.envExtra =
    with config.sops;
    let
      toName = name: builtins.replaceStrings [ "/" "-" ] [ "_" "_" ] (lib.toUpper name);
      toPath = name: secrets."${name}".path;
      convertSecretEnv = name: "export ${toName name}=$(cat ${toPath name})";
      filterSecrets = name: !(lib.hasPrefix "secrets" name);
    in
    builtins.foldl' (acc: elm: acc + elm + "\n") "" (
      builtins.map convertSecretEnv (builtins.filter filterSecrets (builtins.attrNames secrets))
    );
}
