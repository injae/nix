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
            export LANG="en_US.UTF-8"
            export LANGUAGE="ko_KR.UTF-8"
            [ -f ~/.zshrc.local ] && source ~/.zshrc.local # mutable zshrc config
          '';
        in
        lib.mkMerge [ initNormal ];

      envExtra =
        ''
          export PATH=$PATH:/run/current-system/sw/bin/:$HOME/.local/bin

          # disable usage report
          export SCOUT_DISABLE=1

          # rust sccache setting
          export RUSTC_WRAPPER=sccache

          export PATH="$PATH:$HOME/.cargo/bin"

          # cppm binary path
          export PATH="$PATH:$HOME/.cppm/bin"

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
