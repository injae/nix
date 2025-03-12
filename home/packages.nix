{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # General packages for development and system management
    sqlite

    openssl

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
