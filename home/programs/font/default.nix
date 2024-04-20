{ pkgs, ... }:
{
  home.packages = with pkgs; [
    dejavu_fonts
    meslo-lgs-nf
    ffmpeg
    font-awesome
    hack-font
    noto-fonts
    noto-fonts-emoji
    nanum-gothic-coding
    fira-code-nerdfont
    jetbrains-mono
    nerdfonts
  ];
}
