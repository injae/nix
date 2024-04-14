{ pkgs, flake, ... }:
let 
  home-dir = "/Users/${flake.config.people.myself}";
in {
  local.dock.enable = true;
  local.dock.entries = [
    { path = "/Applications/Slack.app/"; }
    { path = "${pkgs.alacritty}/Applications/Alacritty.app/"; }
    { path = "/opt/homebrew/Cellar/emacs-plus@30/30.0.50/Emacs.app/"; }
    {
      path = "${home-dir}/.local/share/";
      section = "others";
      options = "--sort name --view grid --display folder";
    }
    {
      path = "${home-dir}/.local/share/downloads";
      section = "others";
      options = "--sort name --view grid --display stack";
    }
  ];
}
