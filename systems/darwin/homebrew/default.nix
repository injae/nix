{ pkgs, ... }:
{
  homebrew = {
    enable = true;
    casks = pkgs.callPackage ./casks.nix { };
    onActivation = {
      # autoUpdate = true;
      cleanup = "zap";
      # upgrade = true;
    };

    taps = [
      "d12frosted/emacs-plus"
    ];
    brews = [
      {
        name = "emacs-plus@30";
        args = [
          "with-mailutil"
          "with-xwidgets"
          "with-imagemagick"
          "with-native-comp"
          "with-poll"
        ];
      }
    ];

    # $ nix shell nixpkgs#mas
    # $ mas search <app name>
    masApps = {
      Xcode = 497799835;
      KakaoTalk = 869223134;
      MicrosoftRemoteDesktop = 1295203466;
      Yoink = 457622435;
    };
  };
}
