{ pkgs, ... }:
let
  rust-stable = pkgs.rust-bin.stable.latest.default.override {
    extensions = [
      "rust-analysis"
      "rust-src"
      "rustfmt"
      "clippy"
    ];
  };
in
{
  home.packages = with pkgs; [
    rust-stable
    rust-analyzer
    sccache
    libiconv
  ];
}

