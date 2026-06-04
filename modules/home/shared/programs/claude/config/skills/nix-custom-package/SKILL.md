---
name: nix-custom-package
description: "Add a custom package to this Nix flake when it is missing from nixpkgs. Use whenever the user wants to package an upstream tool (Rust/Python/Go/binary/shell) as a custom derivation, expose it via the overlay, and wire it into a home module. Covers metadata gathering, derivation authoring, overlay registration, and nix-build verification."
user-invocable: true
---

# Add a Custom Package to the Nix Flake

Use when a tool is **not in nixpkgs** and must be packaged here. The flow is the same
regardless of language; only the derivation builder (Step 3–4) differs. Rust has extra
handling — see `rust.md`.

Layout this skill touches:
- `packages/<name>.nix` — the derivation (one file per package)
- `overlays/default.nix` — exposes the package as `pkgs.<name>`
- consuming module (e.g. `modules/home/shared/coding/python/default.nix`) — adds it to `home.packages`

Never run `just switch` to verify — use a standalone `nix-build` (Step 7). The user runs `just switch` manually.

---

## Step 1 — Evaluate: Is it really missing from nixpkgs?

Search before packaging. Check `nix search nixpkgs <name>` or https://search.nixos.org.

Answer YES or NO:
- **YES (missing)** → proceed to Step 2.
- **NO (exists)** → stop. Tell the user the existing attribute; no custom package needed.

Commit out loud before proceeding:
> "`<name>` is **[missing / present]** in nixpkgs. [Packaging / Using existing `pkgs.<attr>`]."

---

## Step 2 — Determine the upstream build type

Inspect the upstream repo's manifest to pick the builder. The manifest reveals the type:

| Manifest signal | Type | Builder |
|-----------------|------|---------|
| `Cargo.toml` + `[[bin]]` | Rust binary | `rustPlatform.buildRustPackage` → **read `rust.md`** |
| `pyproject.toml` build-backend = maturin, `bindings = "bin"` | Rust binary wrapped by maturin | treat as Rust binary → **read `rust.md`** |
| `pyproject.toml` (setuptools/hatch/poetry) | Python | `python3.pkgs.buildPythonApplication` (CLI) or `buildPythonPackage` (lib) |
| `go.mod` | Go | `buildGoModule` |
| `package.json` | Node | `buildNpmPackage` |
| prebuilt release binary only | binary | `stdenv.mkDerivation` + `autoPatchelfHook` (Linux) / unpack (Darwin) |
| just wraps existing CLIs | shell glue | `writeShellApplication` (see `packages/cloudflare-k8s-auth.nix`) |

Fetch the manifest from the repo (raw URL) or PyPI JSON. Watch for the **default branch** —
it may be `master`, not `main` (`gh api repos/<owner>/<repo>` → `default_branch`).

Commit out loud before proceeding:
> "Upstream is **[type]** (signal: [manifest]). Builder: **[builder]**. [Reading rust.md / continuing]."

---

## Step 3 — Gather packaging metadata

Collect what the builder needs:
- **version** — latest release tag (`gh api repos/<owner>/<repo>/tags`) or PyPI version.
- **src** — `fetchFromGitHub { owner; repo; tag = "v${version}"; hash; }` (preferred, has Cargo.lock/full tree)
  or `fetchPypi { pname; version; hash; }` for Python sdists.
- **src hash** — `nix store prefetch-file --json --unpack <tarball-url>` → `.hash` (SRI form).
- **runtime deps** — from the manifest (`requires_dist`, `go.mod`, etc.). Rust deps come from `Cargo.lock` (see `rust.md`).

For GitHub tarball prefetch:
```
nix store prefetch-file --json --unpack \
  "https://github.com/<owner>/<repo>/archive/refs/tags/v<version>.tar.gz"
```

Commit out loud before proceeding:
> "version=[v], srcHash=[sha256-…]. Deps: [list / none]. Writing derivation."

---

## Step 4 — Write `packages/<name>.nix`

One function-form derivation per file. Inputs are the builders/fetchers it needs; nothing else.
Match the existing style in `packages/` (no `with pkgs`, explicit inputs, `meta` with `mainProgram`).

Minimal Rust example (full detail in `rust.md`):
```nix
{ lib, rustPlatform, fetchFromGitHub }:
rustPlatform.buildRustPackage rec {
  pname = "<name>";
  version = "0.0.0";
  src = fetchFromGitHub {
    owner = "<owner>";
    repo = "<name>";
    tag = "v${version}";
    hash = "sha256-…";
  };
  cargoLock.lockFile = "${src}/Cargo.lock";
  meta = {
    description = "…";
    homepage = "https://github.com/<owner>/<name>";
    license = lib.licenses.mit;
    mainProgram = "<name>";
  };
}
```

Then `git add packages/<name>.nix` — flakes only see git-tracked files.

---

## Step 5 — Register in `overlays/default.nix`

Add one line in the overlay attrset, mirroring the existing entries:
```nix
<name> = self.callPackage "${packages}/<name>.nix" { };
```
This exposes it as `pkgs.<name>` everywhere.

---

## Step 6 — Register in the consuming module

Add `pkgs.<name>` (bare `<name>` inside `with pkgs`) to the right module's `home.packages`.
Choose by responsibility, e.g. a Python LSP → `modules/home/shared/coding/python/default.nix`.

---

## Step 7 — Verify with standalone `nix-build`

**Gate check — before claiming done, confirm:**
1. The derivation builds in isolation (does not need the overlay or `just switch`):
   ```
   nix-build -E 'let p = import <nixpkgs> {}; in p.callPackage ./packages/<name>.nix {}'
   ```
2. The produced binary runs: `./result/bin/<name> --version`
3. `rm -f result` afterward.

If the build fails on dependency fetching (hash mismatch, network), fix it here — do not
defer to `just switch`. For Rust crates.io `403` errors, see `rust.md`.

Commit out loud:
> "nix-build **[passed / failed]**. Binary reports `[version output]`."

---

## Step 8 — Report

State the three touched files, the verification result, and that applying it is `just switch`
(which the user runs — do not run it or remind them as a closing remark).