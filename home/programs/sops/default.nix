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
    age.sshKeyPaths = [ "${home-dir}/.ssh/id_ed25519" ];
    secrets = {
      "spotify/id" = { };
      "spotify/secret" = { };
      "discord/token" = { };
      "chatgpt/api-key" = { };
    };
  };

  programs.zsh.initExtra = with config.sops;
    let
      toName = name: builtins.replaceStrings [ "/" "-" ] [ "_" "_" ] (lib.toUpper name);
      toPath = name: secrets."${name}".path;
      convertSecretEnv = name: "export ${toName name}=$(cat ${toPath name})";
    in
    builtins.foldl' (acc: elm: acc + elm + "\n") ""
      (builtins.map convertSecretEnv (builtins.attrNames secrets));
}
