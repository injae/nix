{ pkgs, ... }:
let
  # Fix OS window role (needed for window managers like yabai)
  fix-window-role = pkgs.fetchpatch {
    url = "https://raw.githubusercontent.com/d12frosted/homebrew-emacs-plus/refs/heads/master/patches/emacs-28/fix-window-role.patch";
    sha256 = "sha256-+z/KfsBm1lvZTZNiMbxzXQGRTjkCFO4QPlEK35upjsE=";
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
                  ./patches/system-appearance.patch # Make Emacs aware of OS-level light/dark mode
                  ./patches/round-undecorated-frame.patch # Enable rounded window with no decoration
                  #./patches/dedupe-rpath-entries.patch # https://github.com/NixOS/nixpkgs/issues/395169
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
