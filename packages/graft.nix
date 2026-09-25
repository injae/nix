{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  python3,
  tree-sitter,
}:
buildNpmPackage rec {
  pname = "graft";
  version = "0.18.0";

  src = fetchFromGitHub {
    owner = "trailhq";
    repo = "Graft";
    tag = "v${version}";
    hash = "sha256-ylWiVycjkq8twq3PsEprVdJyUbZUDRQNH/a5JC0W98A=";
  };

  npmDepsHash = "sha256-HLU+L4pIWA/07Zh9pcVEQuhR1s3L+hzJ0LBGG2AX568=";

  # tree-sitter grammars are node-gyp native addons
  nativeBuildInputs = [ python3 ];

  # tree-sitter-cli's install script downloads a release binary, which the
  # sandbox cannot reach. Defer the rebuild until that script is replaced by a
  # link to the nixpkgs CLI; tree-sitter-kotlin ships no prebuild, so the
  # remaining install scripts must still run.
  npmRebuildFlags = [ "--ignore-scripts" ];

  preBuild = ''
    : > node_modules/tree-sitter-cli/install.js
    ln -sf ${lib.getExe tree-sitter} node_modules/tree-sitter-cli/tree-sitter
    npm rebuild --offline --no-audit --no-fund
    patchShebangs node_modules
  '';

  meta = {
    description = "Contextual code graph and MCP server for coding agents";
    homepage = "https://github.com/trailhq/Graft";
    license = lib.licenses.mit;
    mainProgram = "graft";
  };
}
