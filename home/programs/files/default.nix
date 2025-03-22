{ pkgs, ... }:
{
  home.packages = with pkgs; [
    mov2gif
    img2webp
    dl-yt
    dl-yt-mp3
  ];
}
