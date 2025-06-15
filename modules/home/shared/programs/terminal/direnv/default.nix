{ config, ... }:
{
  programs = {
    direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
      mise.enable = true;
      config = {
        warn_timeout = 0;
      };
    };
  };

  xdg.configFile = {
    "direnv/lib/use_flake_without_git.sh" = {
      source = config.lib.file.mkOutOfStoreSymlink ./lib/use_flake_without_git.sh;
    };
  };
}
