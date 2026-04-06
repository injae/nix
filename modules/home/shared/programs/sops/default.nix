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
  age-key-file = "${home-dir}/.config/sops/age/keys.txt";
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
    age.keyFile = age-key-file;
    secrets = {
      "spotify/id" = { };
      "spotify/secret" = { };
      "discord/token" = { };
      "chatgpt/api-key" = { };
      "litellm/api-key" = { };
      "secrets/aws-credentials" = {
        path = "${home-dir}/.aws/credentials";
      };
      "secrets/wireless.env" = { };
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
      sops_base_env = "export SOPS_AGE_KEY_FILE=\"${age-key-file}\"\n";
    in
    builtins.foldl' (acc: elm: acc + elm + "\n") sops_base_env (
      builtins.map convertSecretEnv (builtins.filter filterSecrets (builtins.attrNames secrets))
    );
}
