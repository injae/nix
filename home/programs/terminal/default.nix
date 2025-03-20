{
  flake,
  pkgs,
  config,
  ...
}:
{
  imports = with flake.inputs; [
    nix-index-database.hmModules.nix-index
  ];

  programs = {
    nix-index = {
      enable = true;
      enableZshIntegration = true;
    };
    nix-index-database.comma.enable = true;
    command-not-found.enable = false;
    zsh = {
      enable = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      initExtra =
        ''
           # exclude direnv timeout warning
           DIRENV_WARN_TIMEOUT=0

           export LANG="en_US.UTF-8"
           export LANGUAGE="ko_KR.UTF-8"

           export EDITOR=emacsclient

           # emacs vterm
           autoload -U add-zsh-hook
           add-zsh-hook -Uz chpwd (){ print -Pn "\e]2;%m:%2~\a" }

           vterm_printf(){
               if [ -n "$TMUX" ] && ([ "$\{TERM%%-*}" = "tmux" ] || [ "$\{TERM%%-*}" = "screen" ] ); then
                   # Tell tmux to pass the escape sequences through
                   printf "\ePtmux;\e\e]%s\007\e\\" "$1"
               elif [ "$\{TERM%%-*}" = "screen" ]; then
                   # GNU screen (screen, screen-256color, screen-256color-bce)
                   printf "\eP\e]%s\007\e\\" "$1"
               else
                   printf "\e]%s\e\\" "$1"
               fi
           }

          if [[ "$INSIDE_EMACS" = 'vterm' ]]; then
              alias clear='vterm_printf "51;Evterm-clear-scrollback";tput clear'
          fi
          vterm_prompt_end() {
              vterm_printf "51;A$(whoami)@$(hostname):$(pwd)";
          }
          setopt PROMPT_SUBST
          PROMPT=$PROMPT'%{$(vterm_prompt_end)%}'

          # nix-index
          source ${pkgs.nix-index}/etc/profile.d/command-not-found.sh

        ''
        + (
          if pkgs.stdenv.isDarwin then
            ''
              eval "$(/opt/homebrew/bin/brew shellenv)"
            ''
          else
            ""
        );

      envExtra = ''
        export PATH=$PATH:/etc/profiles/per-user/$USER/bin:/run/current-system/sw/bin/:/usr/local/bin

        export PATH="$PATH:$HOME/.cargo/bin"

        export SCOUT_DISABLE=1

        export KUBECONFIG="$HOME/.kube/config:$HOME/.kube/embark:$HOME/.kube/home"

        # emacs lsp-mode
        export LSP_USE_PLISTS=true

        # rust sccache setting
        export RUSTC_WRAPPER=sccache

        # cppm binary path
        export PATH="$PATH:$HOME/.cppm/bin"

        # krew
        export PATH="''${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

        export JAVA_HOME=${pkgs.jdk.home}
      '';
    };

    direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
      mise.enable = true;
      config = {
        warn_timeout = 0;
      };
    };

    starship = {
      enable = true;
      #settings = { };
    };
    zoxide = {
      enable = true;
      enableZshIntegration = true;
    };

    mcfly = {
      enable = true;
      enableZshIntegration = true;
    };

    eza = {
      # exa
      enable = true;
      enableZshIntegration = true;
    };

    fzf = {
      enable = true;
      enableZshIntegration = true;
    };
  };

  home.packages = with pkgs; [
    just
    ripgrep
    ripgrep-all
    fd
    coreutils
    killall
    neofetch
    wget
    zip
    bat
    htop
    iftop
    jq
    tre
    unzip
    ripgrep # rg
    procs
    du-dust
    erdtree
    bottom
    bash-language-server
  ];

  home.shellAliases = {
    ls = "eza -g --time-style=long-iso";
    cat = "bat";
    find = "fd";
    grep = "rg";
    ps = "procs";
    top = "htop";
    tree = "erd -I";
    kube = "kubectl";
  };

  xdg.configFile = {
    "ghostty" = {
      source = config.lib.file.mkOutOfStoreSymlink ./ghostty;
      recursive = true;
    };
    "direnv/lib/use_flake_without_git.sh" = {
      source = config.lib.file.mkOutOfStoreSymlink ./direnv/lib/use_flake_without_git.sh;
    };
  };
}
