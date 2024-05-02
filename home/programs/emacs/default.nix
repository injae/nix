{ pkgs, ... }:
{
  home.file.".emacs.d" = {
    source = ./config;
    recursive = true;
  };

  home.packages = with pkgs; [
    emacs-lsp-booster
    emacs-all-the-icons-fonts
  ] ++ (with pkgs.emacsPackages; [
    vterm
    all-the-icons-nerd-fonts
  ]);
}
