{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
}:
stdenvNoCC.mkDerivation rec {
  pname = "archify-skill";
  version = "2.16.0";

  src = fetchFromGitHub {
    owner = "tt-a1i";
    repo = "archify";
    tag = "v${version}";
    hash = "sha256-0/zwilbuarvLfqH+oNgJoKtQ5cpJKD+Nz3VtOmhZB6U=";
  };

  dontConfigure = true;
  dontBuild = true;

  # Claude Code skill: the skill root is the repo's archify/ subdirectory.
  # test/ and the pre-rendered examples/*.html are not used at runtime.
  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r archify/. $out/
    rm -rf $out/test
    rm -f $out/examples/*.html
    runHook postInstall
  '';

  meta = {
    description = "Claude Code skill for architecture, workflow, sequence, data-flow, and lifecycle diagrams";
    homepage = "https://github.com/tt-a1i/archify";
    license = lib.licenses.mit;
  };
}
