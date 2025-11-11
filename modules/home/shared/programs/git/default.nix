{
  pkgs,
  flake,
  config,
  ...
}:
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
      settings = {
        user = {
          name = user.name;
          email = user.email;
        };
        github.user = user.name;
        core = {
          editor = "emacs";
          autocrlf = "input";
        };
        init.defaultBranch = "main";
        column.ui = "auto";
        tag.sort = "version:refname";
        branch.sort = "-committerdate";
        pull.rebase = true;
        commit.verbose = true;
        help.autocorrect = "prompt";
        diff = {
          algorithm = "histogram";
          colorMoved = "plain";
          mnemonicPrefix = true;
          renames = true;
        };
        push = {
          default = "simple";
          autoSetupRemote = true;
          followTags = true;
        };
        fetch = {
          prune = true;
          pruneTags = true;
          all = true;
        };
        rebase = {
          autoSquash = true;
          autoStash = true;
          updateRefs = true;
        };
      };
      lfs.enable = true;
      includes = [
        { path = config.sops.secrets."secrets/nexon-injae-gitlab".path; }
      ];
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
