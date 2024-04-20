{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # General packages for development and system management
    sqlite

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
  ];
}
