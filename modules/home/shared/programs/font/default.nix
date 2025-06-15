{ pkgs, ... }:
let
  nerd-fonts = builtins.filter pkgs.lib.isDerivation (builtins.attrValues pkgs.nerd-fonts);
in
{
  home.packages =
    with pkgs;
    [
      dejavu_fonts
      meslo-lgs-nf
      ffmpeg
      font-awesome
      hack-font
      noto-fonts-emoji
      nanum-gothic-coding
      jetbrains-mono
    ]
    ++ nerd-fonts;
}
