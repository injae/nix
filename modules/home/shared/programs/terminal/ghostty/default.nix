{ config, ... }:
{
  xdg.configFile = {
    "ghostty" = {
      source = config.lib.file.mkOutOfStoreSymlink ./ghostty;
      recursive = true;
    };
  };
}
