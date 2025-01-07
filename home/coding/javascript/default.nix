{ pkgs, ... }:
{
  home.packages = with pkgs; [
    nodePackages.nodemon
    nodePackages.prettier
    nodePackages.npm # globally install npm
    nodejs

    typescript-language-server
    tailwindcss-language-server
    rustywind # tailwindcss-lsp pulgins
    pnpm
    eslint
    turbo
  ];
}
