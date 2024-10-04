{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # General packages for development and system management
    sqlite

    openssl

    # devenv
    devenv

    # yaml
    yaml-language-server

    # toml
    taplo

    protobuf
    protoc-gen-rust
    protoc-gen-go

    #bazel_7
    cargo-bazel

    # home-cluster
    netbird-ui

    awscli2

    # monitor Internet traffic
    sniffnet
  ];
}
