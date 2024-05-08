{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # General packages for development and system management
    sqlite


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

    #bazel_7
    #bazelisk

    # mise
    # rtx

    # home-cluster
    netbird-ui
  ];
}
