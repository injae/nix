{ pkgs, ... }:
{
  home.packages = with pkgs; [
    nixfmt
    nixd
    #nil
  ];
}
