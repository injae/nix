{ pkgs, flake, config, ... }:
let
  user = flake.config.people.users.${config.home.username};
in
{
  home.packages = with pkgs; [
    git-lfs
    act # github action in local
  ];

  programs = {
    git = {
      enable = true;
      ignores = [ "*.swp" ];
      userName = user.name;
      userEmail = user.email;
      lfs = {
        enable = true;
      };
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
    };

    gh = {
      enable = true;
      settings.git_protocol = "ssh";
    };

    gh-dash = {
      enable = true;
    };
  };
}
