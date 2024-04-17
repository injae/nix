{ pkgs, ... }:
{
  home.file.".emacs.d" = {
    source = ./config;
    recursive = true;
  };

  home.packages = with pkgs; [
    (
      emacsWithPackages (epkgs: [
        epkgs.vterm
        epkgs.all-the-icons-nerd-fonts
      ])
    )

    emacs-lsp-booster
    emacs-all-the-icons-fonts
  ];
}
