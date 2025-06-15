{ pkgs, ... }:
{
  programs = {
    mise = {
      enable = true;
      enableZshIntegration = true;
    };
    direnv = {
      mise.enable = true;
    };
  };
}
