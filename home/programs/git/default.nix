{ pkgs, flake, config, ... }:
let
  user = flake.config.people.users.${config.home.username};
in
{
  home.packages = with pkgs; [
    git-lfs
    act # github action in local
    difftastic
    gitu # git tui like magit
  ];

  programs = {
    git = {
      enable = true;
      ignores = [ "*.swp" ];
      userName = user.name;
      userEmail = user.email;
      lfs.enable = true;
      extraConfig = {
        init.defaultBranch = "main";
        core = {
          editor = "emacs";
          autocrlf = "input";
        };
        pull.rebase = true;
        rebase.autoStash = true;
        github.user = user.name;
      };
      #includes = [
      #  { path = config.sops.secrets."secrets/embark-git".path; }
      #];
    };
    gh = {
      enable = true;
      gitCredentialHelper = {
        enable = true;
        hosts = [
          "https://github.com/injae/"
          "https://github.com/EmbarkStudios/"
          "https://github.com/nexon-public"
        ];
      };
    };
    gh-dash.enable = true;
  };
}
