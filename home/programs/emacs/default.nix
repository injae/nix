{ pkgs, ... }:
let
  # Use poll instead of select to get file descriptors
  poll-patch = pkgs.fetchpatch {
    url = "https://raw.githubusercontent.com/d12frosted/homebrew-emacs-plus/refs/heads/master/patches/emacs-30/poll.patch";
    sha256 = "sha256-jN9MlD8/ZrnLuP2/HUXXEVVd6A+aRZNYFdZF8ReJGfY=";
  };
  # Fix OS window role (needed for window managers like yabai)
  fix-window-role = pkgs.fetchpatch {
    url = "https://raw.githubusercontent.com/d12frosted/homebrew-emacs-plus/refs/heads/master/patches/emacs-28/fix-window-role.patch";
    sha256 = "sha256-+z/KfsBm1lvZTZNiMbxzXQGRTjkCFO4QPlEK35upjsE=";
  };
  # Enable rounded window with no decoration
  round-undecorated-frame-patch = pkgs.fetchpatch {
    url = "https://raw.githubusercontent.com/d12frosted/homebrew-emacs-plus/refs/heads/master/patches/emacs-31/round-undecorated-frame.patch";
    sha256 = "sha256-/SX8rF4GMA7bobfQ4/F9BTSEigeOd9jgN0jvQ1M0MSs=";
  };
  # Make Emacs aware of OS-level light/dark mode
  system-appearance-patch = pkgs.fetchpatch {
    url = "https://raw.githubusercontent.com/d12frosted/homebrew-emacs-plus/refs/heads/master/patches/emacs-30/system-appearance.patch";
    sha256 = "sha256-3QLq91AQ6E921/W9nfDjdOUWR8YVsqBAT/W9c1woqAw=";
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
        (emacs-git-pgtk.overrideAttrs (old: {
          patches =
            (old.patches or [ ])
            ++ (
              if pkgs.stdenv.isDarwin then
                [
                  fix-window-role
                  ./patches/system-appearance.patch
                  ./patches/round-undecorated-frame.patch
                  #round-undecorated-frame-patch
                  #system-appearance-patch
                ]
              else
                [ ]
            );
        })).override
        # https://github.com/NixOS/nixpkgs/issues/395169
        (if pkgs.stdenv.isDarwin then (old: { withNativeCompilation = false; }) else (old: { }))
      )
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
}
