{ pkgs, ... }:
{
  home.packages = with pkgs; [
    dockutil
    mas
    colima
    #yabai
    #skhd
    #spacebar
  ] ++ (with darwin.apple_sdk.frameworks; [
    Foundation
    Security
    SystemConfiguration
  ]);
}
