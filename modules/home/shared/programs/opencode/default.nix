{ ... }: {
  home.file.".config/opencode" = {
    source = ./config;
    recursive = true;
  };
}
