---
name: nix-claude-skill
description: "Install or update a third-party Claude Code skill from an upstream repository as a pinned Nix derivation instead of vendoring its files. Use whenever the user wants to add a skill from a GitHub URL, update an already-installed upstream skill to a new version, or migrate an existing vendored skill under config/skills/ to a pinned derivation."
user-invocable: true
---

# Third-party Claude Skills as Nix Derivations

Claude skills in this repo live in two forms:

| Form | Location | Use for |
|------|----------|---------|
| Vendored | `modules/home/shared/programs/claude/config/skills/<name>/` | Skills authored or edited here. Picked up automatically by `home.file.".claude"` (`source = ./config; recursive = true`). |
| Derivation | `packages/<name>-skill.nix` → `pkgs.<name>-skill` → `home.file.".claude/skills/<name>".source` | Upstream skills consumed unmodified. Version is a pinned tag + hash; updating is a two-line edit. |

A derivation keeps large upstream trees out of git history and makes the installed
version explicit, but the store path is read-only — the skill cannot be edited in place.

Reference implementation: `packages/archify-skill.nix`.

---

## Step 1 — Evaluate: derivation or vendoring?

Answer YES or NO to both:

- **Upstream repo exists** — the skill has a public source repo with tags or releases.
- **Local edits unnecessary** — nothing in this repo needs to patch the skill's content.

Decide:
- **Both YES** → derivation. Continue to Step 2.
- **Either NO** → vendoring. Copy the files into `config/skills/<name>/`, `git add` them, and stop —
  no derivation, no overlay entry, no `claude/default.nix` change.

A skill that is currently vendored but satisfies both conditions is a migration candidate;
before migrating, diff the vendored copy against the upstream tag. Any local delta means the
answer to "local edits unnecessary" is NO — migrating would silently discard that delta.

Commit out loud before proceeding:
> "`<name>`: upstream **[yes/no]**, local edits **[needed/not needed]** → **[derivation / vendoring]**."

---

## Step 2 — Locate the skill root inside the repo

`SKILL.md` is rarely at the repo root. Find which directory is the skill root — the
directory containing `SKILL.md` — because that is what gets installed, not the whole repo.

```bash
gh api "repos/<owner>/<repo>/git/trees/<tag>?recursive=1" \
  --jq '.tree[] | select(.path|endswith("SKILL.md")) | .path'
```

Quote the URL — zsh treats the unquoted `?` as a glob and fails with `no matches found`.

Then list that directory and classify every entry as runtime or not. Typical non-runtime:
`test/`, `benchmarks/`, `.github/`, pre-rendered demo output. Keep anything `SKILL.md`
references — schemas, JSON examples, `references/`, per-directory `README.md` files it links to.

Commit out loud before proceeding:
> "Skill root is `<path>/`. Excluding: `[list / nothing]`."

---

## Step 3 — Pick the version and get the source hash

Use a release tag, never a branch — a branch makes the pin meaningless.

```bash
gh api repos/<owner>/<repo>/releases --jq '.[0].tag_name'
gh api repos/<owner>/<repo>/tags --jq '.[0:5][] | .name'
```

The repo's default branch often carries a `-dev` version ahead of the newest tag. Pin the tag.

```bash
nix store prefetch-file --json --unpack \
  "https://github.com/<owner>/<repo>/archive/refs/tags/v<version>.tar.gz"
```

Take `.hash` from the output. `--unpack` is required: `fetchFromGitHub` hashes the unpacked
tree. The repo's `just get-sha256` recipe hashes the tarball instead and produces a hash that
will not match.

Commit out loud before proceeding:
> "Pinning **v<version>**, hash `sha256-…`."

---

## Step 4 — Check runtime dependencies

Read the skill root's manifest (`package.json`, `pyproject.toml`, …) and separate real
runtime deps from build/test-only deps. Skills that ship pre-generated artifacts often have
an empty runtime dependency set and need only an interpreter.

Then confirm the interpreter is already declared in this repo, e.g.:

```bash
grep -rn "nodejs" modules/ --include="*.nix"
```

- **Declared** → nothing to add.
- **Not declared** → add it to the matching module under `modules/home/shared/coding/` and say so.
- **Real runtime dependencies exist** → this is no longer a plain file copy. Use the proper
  language builder (`buildNpmPackage`, `buildPythonApplication`, …) as described in
  `nix-custom-package`, and wrap the skill root around it.

Commit out loud before proceeding:
> "Runtime deps: **[none / list]**. Interpreter `<x>`: **[already declared in <file> / added]**."

---

## Step 5 — Write `packages/<name>-skill.nix`

A dependency-free skill is a copy, so `stdenvNoCC.mkDerivation` with no configure/build phase:

```nix
{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
}:
stdenvNoCC.mkDerivation rec {
  pname = "<name>-skill";
  version = "<version>";

  src = fetchFromGitHub {
    owner = "<owner>";
    repo = "<repo>";
    tag = "v${version}";
    hash = "sha256-…";
  };

  dontConfigure = true;
  dontBuild = true;

  # Claude Code skill: the skill root is the repo's <path>/ subdirectory.
  # <excluded paths> are not used at runtime.
  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r <path>/. $out/
    rm -rf $out/test
    runHook postInstall
  '';

  meta = {
    description = "<one line>";
    homepage = "https://github.com/<owner>/<repo>";
    license = lib.licenses.<id>;
  };
}
```

`$out` must contain `SKILL.md` at its top level — it is symlinked directly as
`~/.claude/skills/<name>`, so a nested directory hides the skill from Claude Code.

Omit `meta.mainProgram`: this is a skill directory, not a program.

Then stage it — flakes only see git-tracked files:

```bash
git add packages/<name>-skill.nix
```

---

## Step 6 — Register in the overlay and the Claude module

`overlays/default.nix`, alongside the existing entries:

```nix
<name>-skill = self.callPackage "${packages}/<name>-skill.nix" { };
```

`modules/home/shared/programs/claude/default.nix`, next to the existing `home.file.".claude"`:

```nix
home.file.".claude/skills/<name>".source = pkgs.<name>-skill;
```

This coexists with the recursive `./config` copy because Home Manager links each config file
individually. It collides only if `config/skills/<name>/` also exists — when migrating a
vendored skill, `git rm -r` that directory in this step.

---

## Step 7 — Verify

**Gate check — before reporting success, all four must have run and passed:**

1. The derivation builds standalone, without the overlay:
   ```bash
   nix-build -E 'let p = import <nixpkgs> {}; in p.callPackage ./packages/<name>-skill.nix {}'
   ls result/SKILL.md && du -sh -L result/
   ```
2. The overlay resolves it:
   ```bash
   rm -f result
   nix eval --no-warn-dirty ".#packages.aarch64-darwin.<name>-skill.outPath"
   ```
3. The Home Manager file set builds — this is what catches symlink collisions:
   ```bash
   nix build --no-warn-dirty --no-link --print-out-paths \
     '.#darwinConfigurations.nieel-m3.config.home-manager.users.nieel.home-files'
   ```
   Then confirm the link: `ls -l <out>/.claude/skills/`
4. If the skill ships a CLI, smoke-test it from the read-only store — this proves the skill
   does not need to write inside its own directory:
   ```bash
   cd "$CLAUDE_JOB_DIR/tmp" 2>/dev/null || cd /tmp
   node <store-path>/bin/<cli>.mjs doctor
   ```

Never verify with `just switch`. The user runs that manually.

Commit out loud:
> "nix-build **[pass/fail]**, overlay eval **[pass/fail]**, home-files **[pass/fail]**, CLI smoke **[pass/fail/n-a]**."

---

## Step 8 — Report

State the touched files, the pinned version, the installed size, each verification result,
and the update command from Step 9. Do not tell the user to run `just switch`.

---

## Step 9 — Updating an installed skill

Updating is a version bump plus a new hash. Nothing else changes.

1. Read the pinned version:
   ```bash
   grep -n 'version' packages/<name>-skill.nix
   ```
2. Find the newest tag:
   ```bash
   gh api repos/<owner>/<repo>/releases --jq '.[0].tag_name'
   ```
   If it equals the pinned version, stop and say the skill is current.
3. Fetch the new hash with the Step 3 command against the new tag.
4. Edit `version` and `hash` in `packages/<name>-skill.nix`.
5. Re-run the Step 7 gate check in full. A new upstream version can move `SKILL.md`, rename
   the skill root, add runtime dependencies, or drop a file the `installPhase` deletes —
   `installPhase` failures and a missing `$out/SKILL.md` are the expected symptoms.
6. Read the upstream release notes for behavior changes worth telling the user about:
   ```bash
   gh api repos/<owner>/<repo>/releases --jq '.[0].body' | head -40
   ```

If the skill has its own update checker (archify runs `scripts/check-update.mjs`), treat its
notice as information only. It cannot update a store path, so the fix is always this step.
