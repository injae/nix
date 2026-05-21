{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # markdown lsp server
    marksman
  ];
}
