{ pkgs, lib, ... }:
let
  # Fix OS window role (needed for window managers like yabai)

  # https://github.com/d12frosted/homebrew-emacs-plus/tree/master/patches/emacs-31
  fix-window-role = pkgs.fetchpatch {
    url = "https://raw.githubusercontent.com/d12frosted/homebrew-emacs-plus/refs/heads/master/patches/emacs-31/fix-ns-x-colors.patch";
    sha256 = "sha256-oe3DFgEXwp0cZJl+ufWqTonaeWSliikTRsVDNbcy4Yw=";
  };

  rounded-undecorated-frame-patch = pkgs.fetchpatch {
    url = "https://raw.githubusercontent.com/d12frosted/homebrew-emacs-plus/refs/heads/master/patches/emacs-31/round-undecorated-frame.patch";
    sha256 = "sha256-KCMEvJzN1OkwFYoMLpZghvdeoO1Ckcxk3Mo19YAf850=";
  };

  system-appearance-patch = pkgs.fetchpatch {
    url = "https://raw.githubusercontent.com/d12frosted/homebrew-emacs-plus/refs/heads/master/patches/emacs-31/system-appearance.patch";
    sha256 = "sha256-4+2U+4+2tpuaThNJfZOjy1JPnneGcsoge9r+WpgNDko=";
  };

  # darwin: NS (Cocoa) build — emacs-plus patches target the NS build
  # linux: pgtk build (Wayland-native)
  emacsBase = if pkgs.stdenv.isDarwin then pkgs.emacs-unstable else pkgs.emacs-unstable-pgtk;

in
{
  home.file.".emacs.d" = {
    source = ./config;
    recursive = true;
  };

  home.file.".config/rassumfrassum" = {
    source = ./rassumfrassum;
    recursive = true;
  };

  home.packages =
    with pkgs;
    [
      (
        (emacsBase.overrideAttrs (old: {
          patches =
            (old.patches or [ ])
            ++ (
              if pkgs.stdenv.isDarwin then
                [
                  fix-window-role
                  rounded-undecorated-frame-patch
                  system-appearance-patch
                ]
              else
                [ ]
            );
        })).override
        {
          withNativeCompilation = true;
        }
      )
    ]
    ++ (with pkgs; [
      emacs-all-the-icons-fonts
      copilot-language-server
      glibtool
      rassumfrassum
    ]);

  programs.zsh = {
    initContent =
      let
        normal = lib.mkOrder 1000 ''
          export EDITOR=emacsclient

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
        last = lib.mkOrder 1500 ''
          vterm_prompt_end() {
              vterm_printf "51;A$(whoami)@$(hostname):$(pwd)"
          }
          setopt PROMPT_SUBST
          PROMPT=$PROMPT'%{$(vterm_prompt_end)%}'
        '';
      in
      lib.mkMerge [
        normal
        last
      ];
    envExtra = ''
      # emacs lsp-mode
      export LSP_USE_PLISTS=true
    '';
  };
}
