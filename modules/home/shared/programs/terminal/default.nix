{
  pkgs,
  ...
}:
let
  exclude = [ "default.nix" ];
in
{
  imports =
    with builtins;
    map (fn: ./${fn}) (filter (fn: !(elem fn exclude)) (attrNames (readDir ./.)));

  home.packages = with pkgs; [
    just
    coreutils
    killall
    neofetch
    wget
    zip
    iftop
    jq
    tre # agrep
    unzip
    du-dust
    bottom
    bash-language-server
  ];

  programs = {
    command-not-found.enable = false;
    starship.enable = true;
  };
}
