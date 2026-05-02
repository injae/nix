{ ... }:
{
  homebrew = {
    taps = [ ];
    brews = [ ];
    casks = [
      "tableplus"
    ];

    # $ nix shell nixpkgs#mas
    # $ mas search <app name>
    masApps = { };
  };
}
