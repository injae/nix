{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # General packages for development and system management
    sqlite

    openssl

    # devenv
    devenv

    # php
    php

    # yaml
    yaml-language-server

    # toml
    taplo

    protobuf
    protoc-gen-rust
    protoc-gen-go

    bazel_7_1_2
    bazel-buildtools
    cargo-bazel

    # home-cluster
    netbird-ui
  ];
}
