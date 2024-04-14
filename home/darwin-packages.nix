{ pkgs, ... }:
{
  home.packages = with pkgs; [
    dockutil
    mas
    darwin.apple_sdk.frameworks.Foundation
    colima
    #yabai
    #skhd
    #spacebar
  ];
}
