{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
}:
let
  # Upstream tags every release as agent-skills-<full commit sha>.
  rev = "063bee94c3f4df8453406c830b0a7df0f2860278";
in
stdenvNoCC.mkDerivation {
  pname = "vercel-agent-skills";
  version = builtins.substring 0 8 rev;

  src = fetchFromGitHub {
    owner = "vercel-labs";
    repo = "agent-skills";
    tag = "agent-skills-${rev}";
    hash = "sha256-tTSJf53OQltUfxTH4hdqcnw5ywCjCZP8/JqQ593cyB8=";
  };

  dontConfigure = true;
  dontBuild = true;

  # Claude Code skills: only the four skills wired into ~/.claude/skills.
  # Upstream directory names lack the vercel- prefix that the SKILL.md
  # frontmatter declares, so rename on install to match the skill name.
  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r skills/composition-patterns $out/vercel-composition-patterns
    cp -r skills/react-best-practices $out/vercel-react-best-practices
    cp -r skills/react-view-transitions $out/vercel-react-view-transitions
    cp -r skills/web-design-guidelines $out/web-design-guidelines
    runHook postInstall
  '';

  meta = {
    description = "Vercel's Claude Code skills for React, Next.js, and web design review";
    homepage = "https://github.com/vercel-labs/agent-skills";
    license = lib.licenses.mit;
  };
}
