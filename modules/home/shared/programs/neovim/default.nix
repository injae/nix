{ pkgs, ... }:
{
  programs.neovim = {
    enable = true;
    withRuby = false;
    withPython3 = false;
  };

  home.packages = with pkgs; [
    lua-language-server
    luajitPackages.luarocks
  ];
}
