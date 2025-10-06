{ pkgs, ... }:
{
  programs.neovim = {
    enable = true;
  };

  home.packages = with pkgs; [
    lua-language-server
    luajitPackages.luarocks
  ];
}
