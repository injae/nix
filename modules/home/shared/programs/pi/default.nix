{ ... }:
{
  home.file.".pi/agent/AGENTS.md" = {
    source = ./config/AGENTS.md;
  };

  home.file.".pi/agent/settings.json" = {
    source = ./config/settings.json;
  };

  home.file.".pi/agent/models.json" = {
    source = ./config/models.json;
  };

  home.file.".pi/agent/extensions" = {
    source = ./config/extensions;
    recursive = true;
  };

  home.file.".pi/agent/skills" = {
    source = ./config/skills;
    recursive = true;
  };
}
