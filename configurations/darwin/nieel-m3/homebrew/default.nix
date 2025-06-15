{ pkgs, flake, ... }:
{
  homebrew = {
    enable = true;
    user = flake.config.people.myself;
    casks = pkgs.callPackage ./casks.nix { };
    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
      upgrade = true;
    };

    taps = [
      #"d12frosted/emacs-plus"
    ];
    brews = [
      "bazelisk"
      "bash"
      "ksops"
      #{
      #  name = "emacs-plus@31";
      #  args = [
      #    "with-mailutil"
      #    "with-xwidgets"
      #    "with-imagemagick"
      #    "with-native-comp"
      #    "with-poll"
      #  ];
      #}
    ];

    # $ nix shell nixpkgs#mas
    # $ mas search <app name>
    masApps = {
      Xcode = 497799835;
      KakaoTalk = 869223134;
      WindowsApp = 1295203466; # Microsoft Remote Desktop
      Yoink = 457622435;
      MicrosoftOutlook = 985367838;
      MicrosoftPowerPoint = 462062816;
      MicrosoftWord = 462054704;
      MicrosoftExcel = 462058435;
      Magnet = 441258766;
    };
  };
}
