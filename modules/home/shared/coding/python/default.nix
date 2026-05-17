{ pkgs, ... }:
{
  home.packages = with pkgs; [
    maturin
    ruff
    mypy
    uv
    ty
    python3
  ];
}
