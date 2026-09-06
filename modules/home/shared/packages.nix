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

    zstd

    mdbook

    # structural search and rewrite, driven by the ast-grep MCP tool
    ast-grep

    copilot-language-server
    litecli

    llama-cpp
  ];
}
