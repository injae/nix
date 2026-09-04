{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
}:
stdenvNoCC.mkDerivation rec {
  pname = "codex-plugin";
  version = "1.0.6";

  src = fetchFromGitHub {
    owner = "openai";
    repo = "codex-plugin-cc";
    tag = "v${version}";
    hash = "sha256-S/R4kHTcIHBcG0TRX063C7ILXZZm0oMqunchPGg6ToU=";
  };

  dontConfigure = true;
  dontBuild = true;

  # Marketplace repo: the plugin itself lives in plugins/codex, so only that
  # subtree is installed. Dropped in ~/.claude/skills/codex, where Claude Code
  # auto-loads it as codex@skills-dir. Scripts are plain .mjs run by node; the
  # gitignored .generated tree is referenced only from .d.ts type declarations,
  # so no build step is needed. The npm workspace and tests at the repo root
  # are build-time only.
  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r plugins/codex/. $out/
    runHook postInstall
  '';

  meta = {
    description = "Codex plugin for Claude Code: delegate tasks and code review to Codex";
    homepage = "https://github.com/openai/codex-plugin-cc";
    license = lib.licenses.asl20;
  };
}
