{ pkgs, lib, ... }:
{
  programs = {
    zsh = {
      enable = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      initContent =
        let
          initNormal = lib.mkOrder 1000 ''
            # exclude direnv timeout warning
            DIRENV_WARN_TIMEOUT=0

            export LANG="en_US.UTF-8"
            export LANGUAGE="ko_KR.UTF-8"

            export EDITOR=emacsclient

            [ -f ~/.zshrc.local ] && source ~/.zshrc.local

            # emacs vterm
            autoload -U add-zsh-hook
            add-zsh-hook -Uz chpwd (){ print -Pn "\e]2;%m:%2~\a" }

            vterm_printf() {
                if [ -n "$TMUX" ] \
                    && { [ "''${TERM%%-*}" = "tmux" ] \
                        || [ "''${TERM%%-*}" = "screen" ]; }; then
                    # Tell tmux to pass the escape sequences through
                    printf "\ePtmux;\e\e]%s\007\e\\" "$1"
                elif [ "''${TERM%%-*}" = "screen" ]; then
                    # GNU screen (screen, screen-256color, screen-256color-bce)
                    printf "\eP\e]%s\007\e\\" "$1"
                else
                    printf "\e]%s\e\\" "$1"
                fi
            }

            if [[ "$INSIDE_EMACS" = 'vterm' ]]; then
                alias clear='vterm_printf "51;Evterm-clear-scrollback";tput clear'
            fi
          '';
          initLast = lib.mkOrder 1500 ''
            vterm_prompt_end() {
                vterm_printf "51;A$(whoami)@$(hostname):$(pwd)"
            }
            setopt PROMPT_SUBST
            PROMPT=$PROMPT'%{$(vterm_prompt_end)%}'
          '';
        in
        lib.mkMerge [
          initNormal
          initLast
        ];

      envExtra =
        ''
          export PATH=$PATH:/etc/profiles/per-user/$USER/bin:/run/current-system/sw/bin/:/usr/local/bin:$HOME/.local/bin

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
        ''
        + (
          if pkgs.stdenv.isDarwin then
            ''
              eval "$(/opt/homebrew/bin/brew shellenv)"
            ''
          else
            ""
        );
    };
  };
}
