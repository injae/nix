{ pkgs, flake, ... }:
let
  trustedTap = tap:
    if builtins.isString tap then
      {
        name = tap;
        trusted = true;
      }
    else
      tap // { trusted = tap.trusted or true; };
in
{
  environment.systemPackages = with pkgs; [ mas ];
  homebrew = {
    enable = true;
    user = flake.config.people.myself;
    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
      upgrade = false;
    };

    taps = map trustedTap [
      "hcavarsan/kftray"
      "theboredteam/boring-notch"
    ];
    brews = [
      "bazelisk"
      "bash"
      "ksops"
      "opencode"
      "pi-coding-agent"
    ];
    casks = pkgs.callPackage ./casks.nix { };

    # $ nix shell nixpkgs#mas
    # $ mas search <app name>
    masApps = {
      Xcode = 497799835;
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
