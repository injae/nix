{ pkgs, lib, ... }:
let
  # Fix OS window role (needed for window managers like yabai)

  fix-window-role = pkgs.fetchpatch {
    url = "https://raw.githubusercontent.com/d12frosted/homebrew-emacs-plus/refs/heads/master/patches/emacs-28/fix-window-role.patch";
    sha256 = "sha256-+z/KfsBm1lvZTZNiMbxzXQGRTjkCFO4QPlEK35upjsE=";
  };

  rounded-undecorated-frame-patch-30 = pkgs.fetchpatch {
    url = "https://raw.githubusercontent.com/d12frosted/homebrew-emacs-plus/refs/heads/master/patches/emacs-30/round-undecorated-frame.patch";
    sha256 = "sha256-dFH4D1WYQOVOagUuVdEQB3irxV+Y8dDAOKJOJXc/KHQ=";
  };
  # https://raw.githubusercontent.com/d12frosted/homebrew-emacs-plus/refs/heads/master/patches/emacs-30/system-appearance.patch
  system-appearance-patch-30 = pkgs.fetchpatch {
    url = "https://raw.githubusercontent.com/d12frosted/homebrew-emacs-plus/refs/heads/master/patches/emacs-30/system-appearance.patch";
    sha256 = "sha256-nrPOgGQAJb/5brrrWJNDARY2jWNJ9OsMtO+LPVhHfbY=";
  };

in
{
  home.file.".emacs.d" = {
    source = ./config;
    recursive = true;
  };

  home.packages =
    with pkgs;
    [
      (
        (emacs-unstable-pgtk.overrideAttrs (old: {
          patches =
            (old.patches or [ ])
            ++ (
              if pkgs.stdenv.isDarwin then
                [
                  fix-window-role
                  rounded-undecorated-frame-patch-30
                  system-appearance-patch-30
                ]
              else
                [ ]
            );
        })).override
        {
          # https://github.com/NixOS/nixpkgs/issues/395169
          withNativeCompilation = (!pkgs.stdenv.isDarwin);
          withPgtk = (pkgs.stdenv.isDarwin);
        }
      )
      # (
      #   (emacs-git-pgtk.overrideAttrs (old: {
      #     patches =
      #       (old.patches or [ ])
      #       ++ (
      #         if pkgs.stdenv.isDarwin then
      #           [
      #             ./patches/system-appearance.patch # Make Emacs aware of OS-level light/dark mode
      #             ./patches/round-undecorated-frame.patch # Enable rounded window with no decoration
      #             #./patches/dedupe-rpath-entries.patch # https://github.com/NixOS/nixpkgs/issues/395169
      #             #round-undecorated-frame-patch
      #             #system-appearance-patch
      #           ]
      #         else
      #           [ ]
      #       );
      #   })).override
      #   {
      #     # https://github.com/NixOS/nixpkgs/issues/395169
      #     withNativeCompilation = (!pkgs.stdenv.isDarwin);
      #     withPgtk = (pkgs.stdenv.isDarwin);
      #   }
      # )
    ]
    ++ (with pkgs; [
      # https://github.com/NixOS/nixpkgs/issues/395169
      (emacs-lsp-booster.overrideAttrs (old: {
        doCheck = false;
        nativeCheckInputs = [ ];
      }))
      emacs-all-the-icons-fonts
      copilot-language-server
      glibtool
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
