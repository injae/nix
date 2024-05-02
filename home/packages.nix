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

    # devenv
    devenv

    # php
    php

    # yaml
    yaml-language-server

    # toml
    taplo


    #protobuf
    protobuf

    # bazel
    bazelisk

    # mise
    mise
  ];
}
