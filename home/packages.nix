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

    # monitor Internet traffic
    # sniffnet

    yt-dlp
    dependabot-cli
  ];
}
