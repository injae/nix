{ pkgs, ... }:
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

  home.file.".pi/agent/skills/vercel-composition-patterns".source =
    "${pkgs.vercel-agent-skills}/vercel-composition-patterns";
  home.file.".pi/agent/skills/vercel-react-best-practices".source =
    "${pkgs.vercel-agent-skills}/vercel-react-best-practices";
  home.file.".pi/agent/skills/vercel-react-view-transitions".source =
    "${pkgs.vercel-agent-skills}/vercel-react-view-transitions";
  home.file.".pi/agent/skills/web-design-guidelines".source =
    "${pkgs.vercel-agent-skills}/web-design-guidelines";
}
