{ pkgs, ... }:
{
  home.packages = with pkgs; [
    nixfmt-rfc-style
    nixpkgs-fmt
    #nil
    nixd
  ];
}
