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

    # bazel
    bazelisk

    # mise
    mise

    # home-cluster
    netbird-ui
  ];
}
