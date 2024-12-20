{ pkgs, ... }:
{
  home.packages = with pkgs; [
    maturin
    (python311.withPackages (ppkg: [
      ppkg.pip
      ppkg.virtualenv
      ppkg.debugpy
      # emacsPackages.lsp-bridge
      ppkg.epc
      ppkg.orjson
      ppkg.sexpdata
      ppkg.six
      ppkg.setuptools
      ppkg.rapidfuzz
      # ---------------
    ]))
    poetry
    basedpyright
    ruff
    mypy
    uv
  ];
}
