{ pkgs, ... }:
let
  # Fix OS window role (needed for window managers like yabai)
  fix-window-role = pkgs.fetchpatch {
    url = "https://raw.githubusercontent.com/d12frosted/homebrew-emacs-plus/refs/heads/master/patches/emacs-28/fix-window-role.patch";
    sha256 = "sha256-+z/KfsBm1lvZTZNiMbxzXQGRTjkCFO4QPlEK35upjsE=";
  };
  # Use poll instead of select to get file descriptors
  poll-patch = pkgs.fetchpatch {
    url = "https://raw.githubusercontent.com/d12frosted/homebrew-emacs-plus/refs/heads/master/patches/emacs-30/poll.patch";
    sha256 = "sha256-jN9MlD8/ZrnLuP2/HUXXEVVd6A+aRZNYFdZF8ReJGfY=";
  };
  # Enable rounded window with no decoration
  round-undecorated-frame-patch = pkgs.fetchpatch {
    url = "https://raw.githubusercontent.com/d12frosted/homebrew-emacs-plus/refs/heads/master/patches/emacs-30/round-undecorated-frame.patch";
    sha256 = "sha256-uYIxNTyfbprx5mCqMNFVrBcLeo+8e21qmBE3lpcnd+4=";
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

  home.packages = with pkgs; [
      (emacs-pgtk.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ (
          if pkgs.stdenv.isDarwin then [
            fix-window-role
            #poll-patch
            round-undecorated-frame-patch
            system-appearance-patch
          ]
          else [ ]
        );
      }))
    ] ++ (with pkgs; [
      emacs-lsp-booster
      emacs-all-the-icons-fonts
    ]) ++ (with pkgs.emacsPackages; [
      vterm
      all-the-icons-nerd-fonts
    ]);
}
