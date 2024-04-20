{ pkgs, ... }:
{
  home.packages = with pkgs; [
    go
    gopls
    delve
    godef
    gotools
    golangci-lint
    golangci-lint-langserver
  ];
}
