{ ... }:
{
  # show current system settings
  # defaults read
  system = {
    stateVersion = 6;

    defaults = {
      # defaults read com.apple.screensaver
      screensaver = {
        askForPasswordDelay = 10;
      };

      # defaults read NSGlobalDomain
      NSGlobalDomain = {
        AppleShowAllExtensions = true;
        ApplePressAndHoldEnabled = false;

        # 120, 90, 60, 30, 12, 6, 2
        KeyRepeat = 2;

        # 120, 94, 68, 35, 25, 15
        InitialKeyRepeat = 15;

        "com.apple.mouse.tapBehavior" = 1;
        "com.apple.sound.beep.volume" = 0.0;
        "com.apple.sound.beep.feedback" = 0;
        "com.apple.springing.enabled" = true;
        "com.apple.springing.delay" = 0.5;
      };

      # defaults read com.apple.dock
      dock = {
        autohide = true;
        show-recents = false;
        launchanim = true;
        orientation = "bottom";
        tilesize = 48;
      };

      # defaults read com.apple.finder
      finder = {
        _FXShowPosixPathInTitle = false;
      };

      # defaults read com.apple.AppleMultitouchTrackpad
      trackpad = {
        Clicking = true;
        TrackpadThreeFingerDrag = true;
      };
    };

    # https://github.com/nix-darwin/nix-darwin/blob/master/modules/system/keyboard.nix
    keyboard = {
      enableKeyMapping = true;
      remapCapsLockToControl = true;
    };
  };
}
