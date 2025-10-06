{ pkgs, ... }:
{
  home.packages = with pkgs; [
    nodejs_latest
    prettier

    typescript-language-server
    typescript
    tailwindcss-language-server
    rustywind # tailwindcss-lsp pulgins
    pnpm
    eslint
    turbo
  ];
}
