{ pkgs, config, ... }:
{
  home.packages = with pkgs; [
    awscli2
    amazon-ecr-credential-helper
  ];
}
