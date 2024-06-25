{ pkgs, ... }:
{
  home.packages = with pkgs; [
    go
    gopls
    delve
    godef
    gotools
    gotests
    golangci-lint
    golangci-lint-langserver
  ];
}
