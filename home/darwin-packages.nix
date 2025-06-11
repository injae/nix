{ pkgs, ... }:
{
  home.packages = with pkgs; [
    dockutil
    mas
    colima
    #yabai
    #skhd
    #spacebar
  ];
}
