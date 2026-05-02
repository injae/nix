{ ... }:
{
  homebrew = {
    taps = [ ];
    brews = [ ];
    casks = [ ];

    # $ nix shell nixpkgs#mas
    # $ mas search <app name>
    masApps = {
      KakaoTalk = 869223134;
    };
  };
}
