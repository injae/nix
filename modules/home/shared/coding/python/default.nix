{ pkgs, ... }:
{
  home.packages = with pkgs; [
    maturin
    poetry
    basedpyright
    ruff
    mypy
    uv
  ];
}
