{ pkgs, ... }:
{
  home.packages = with pkgs; [
    nodejs_latest
    prettier

    typescript-language-server
    typescript
    tailwindcss-language-server
    vue-language-server

    # css, html, eslint, json, markdown lsp
    vscode-langservers-extracted

    rustywind # tailwindcss-lsp pulgins
    pnpm
    eslint
    turbo
  ];
}
