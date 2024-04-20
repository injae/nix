{ pkgs, ... }:
{
  home.packages = with pkgs; [
    nodePackages.nodemon
    nodePackages.prettier
    nodePackages.npm # globally install npm
    nodejs
  ];
}
