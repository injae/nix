{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
}:
stdenvNoCC.mkDerivation rec {
  pname = "superpowers-plugin";
  version = "6.3.0";

  src = fetchFromGitHub {
    owner = "obra";
    repo = "superpowers";
    tag = "v${version}";
    hash = "sha256-EsGNO0dULWf5Bx6bGrCv2kI2Z8aKH0kRvGiuN23wChQ=";
  };

  dontConfigure = true;
  dontBuild = true;

  # Claude Code plugin: dropped in ~/.claude/skills/superpowers, where Claude
  # Code auto-loads it as superpowers@skills-dir. Only the manifest, skills and
  # hooks are read at runtime; tests, docs and the other agents' plugin
  # directories are not.
  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r .claude-plugin skills hooks LICENSE README.md $out/
    runHook postInstall
  '';

  meta = {
    description = "Superpowers plugin for Claude Code: TDD, debugging and collaboration skills";
    homepage = "https://github.com/obra/superpowers";
    license = lib.licenses.mit;
  };
}
