{ pkgs, ... }:
{
  home.packages = with pkgs; [
    go
    gopls
    delve
    godef
    gotests
    golangci-lint
    golangci-lint-langserver
  ];
}
