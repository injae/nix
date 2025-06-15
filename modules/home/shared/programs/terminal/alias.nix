{ pkgs, ... }:
{
  programs = {
    zoxide = {
      enable = true;
      enableZshIntegration = true;
    };

    mcfly = {
      enable = true;
      enableZshIntegration = true;
    };

    # exa
    eza = {
      enable = true;
      enableZshIntegration = true;
    };

    fzf = {
      enable = true;
      enableZshIntegration = true;
    };
  };

  home.packages = with pkgs; [
    ripgrep
    ripgrep-all
    fd
    bat
    htop
    erdtree
    tree
    procs
  ];

  home.shellAliases = {
    ls = "eza -g --time-style=long-iso";
    cat = "bat";
    find = "fd";
    grep = "rg";
    top = "htop";
    vtree = "erd -I -H --layout inverted";
    kube = "kubectl";
    ps = "procs";
  };
}
