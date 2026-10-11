{ ... }:
{
  homebrew = {
    taps = [ ];
    brews = [
      "andyyyy64/whichllm/whichllm"
    ];
    casks = [
      # ComfyUI Desktop
      "comfy"
    ];

    # $ nix shell nixpkgs#mas
    # $ mas search <app name>
    masApps = {
      KakaoTalk = 869223134;
    };
  };
}
