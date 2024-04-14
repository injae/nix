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
    # General packages for development and system management
    act
    alacritty

    openssh
    sqlite
    jetbrains-mono

    # Encryption and security tools
    age
    gnupg
    sops
    ssh-to-pgp
    ssh-to-age

    # container
    docker
    docker-compose
    kubectl
    k9s
    ngrok
    #netbird
    #netbird-ui

    # terraform
    tflint


    # devenv
    devenv

    # emacs lsp
    emacs-lsp-booster
    emacs-all-the-icons-fonts
    emacsPackages.all-the-icons-nerd-fonts

    # Media-related packages
    dejavu_fonts
    meslo-lgs-nf
    ffmpeg
    font-awesome
    hack-font
    noto-fonts
    noto-fonts-emoji
    nanum-gothic-coding
    fira-code-nerdfont
    nerdfonts

    # Node.js development tools
    nodePackages.nodemon
    nodePackages.prettier
    nodePackages.npm # globally install npm
    nodejs

    # Python
    rye
    maturin
    (
      python311.withPackages (ppkg: [
        ppkg.pip
        ppkg.virtualenv
        ppkg.debugpy
        # emacsPackages.lsp-bridge
        ppkg.epc
        ppkg.orjson
        ppkg.sexpdata
        ppkg.six
        ppkg.setuptools
        ppkg.paramiko
        ppkg.rapidfuzz
        # ---------------
      ])
    )
    pipx
    poetry
    nodePackages.pyright
    ruff
    ruff-lsp
    mypy

    # build-tool
    ninja
    gnumake

    # c-c++
    #stdenv
    #clangStdenv
    #vscode-extensions.vadimcn.vscode-lldb
    #llvmPackages_17.stdenv
    #llvmPackages_17.libcxxStdenv
    #llvmPackages_17.bintools-unwrapped
    #llvmPackages_17.clangUseLLVM
    #clang
    #gcc13
    ccls
    ccache
    lcov

    # cmake
    cmake
    cmake-format
    cmake-language-server

    # golang
    go
    gopls
    delve
    godef
    gotools
    golangci-lint
    golangci-lint-langserver

    # php
    php

    # nix
    nixfmt-rfc-style
    nixpkgs-fmt
    nil

    # yaml
    yaml-language-server

    #protobuf
    protobuf

    # rust
    sccache
    libiconv
    rust-stable
    rust-analyzer
  ];
}
