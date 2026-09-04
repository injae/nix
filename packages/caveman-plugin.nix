{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
}:
stdenvNoCC.mkDerivation rec {
  pname = "caveman-plugin";
  version = "2.6.0";

  src = fetchFromGitHub {
    owner = "JuliusBrussee";
    repo = "caveman";
    tag = "v${version}";
    hash = "sha256-tEQDv0sIsCzdzaq/tdUSN8nb2xmQJkmjPtq8wKChqvQ=";
  };

  dontConfigure = true;
  dontBuild = true;

  # Claude Code plugin: dropped in ~/.claude/skills/caveman, where Claude Code
  # auto-loads it as caveman@skills-dir. Runtime reads src/hooks (node hooks and
  # the statusline script), skills, agents (cavecrew-model-overrides.js),
  # commands (caveman-parse.js) and docs (linked from skills). The Go proxy,
  # pnpm workspace and test trees are build-time only.
  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r .claude-plugin src skills agents commands docs LICENSE README.md $out/
    runHook postInstall
  '';

  meta = {
    description = "Caveman plugin for Claude Code: ultra-compressed communication mode";
    homepage = "https://github.com/JuliusBrussee/caveman";
    license = lib.licenses.mit;
  };
}
