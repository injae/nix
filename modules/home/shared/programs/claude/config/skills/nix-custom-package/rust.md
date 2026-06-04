# Rust Packages — Extra Handling

Read this when Step 2 identified the upstream as a **Rust binary** — either a plain
`Cargo.toml` with `[[bin]]`, or a `pyproject.toml` whose build-backend is `maturin` with
`bindings = "bin"`. In the maturin case there is **no real Python**: maturin only wraps a
Rust binary, so package it directly with `rustPlatform.buildRustPackage` and ignore Python.

---

## Step R1 — Confirm `Cargo.lock` is committed

`buildRustPackage` needs the lockfile to vendor crates. Check the repo:
```
curl -s -o /dev/null -w "%{http_code}\n" \
  "https://raw.githubusercontent.com/<owner>/<repo>/<default-branch>/Cargo.lock"
```
- **200** → use `cargoLock.lockFile = "${src}/Cargo.lock";` (no separate hash needed).
- **404** → lockfile not committed. Either generate one (`cargo generate-lockfile`) and
  carry it in `packages/`, or fall back to `cargoHash` (see Step R3 caveat).

---

## Step R2 — Choose the vendoring mechanism: `cargoLock` over `cargoHash`

Prefer `cargoLock.lockFile = "${src}/Cargo.lock"` instead of `cargoHash`.

Why: this environment's network **blocks the crates.io API download endpoint without a
User-Agent header** (`https://crates.io/api/v1/crates/<crate>/<ver>/download` → `403`).
- `cargoHash` uses the newer `fetchCargoVendor` → `fetch-cargo-vendor-util`, which sends
  **no User-Agent** → every crate fetch fails with `403`.
- `cargoLock.lockFile` uses `importCargoLock`, which fetches via `fetchurl` (curl sets a
  User-Agent) → the endpoint answers `302` and the redirect is followed → works.

Confirm the cause if you hit `403`:
```
curl -sI "https://crates.io/api/v1/crates/either/1.15.0/download" -o /dev/null -w "no-UA: %{http_code}\n"   # 403
curl -sI -A nix "https://crates.io/api/v1/crates/either/1.15.0/download" -o /dev/null -w "UA: %{http_code}\n" # 302
```
If you see `403 / 302`, that is this exact issue — switch to `cargoLock.lockFile`.

---

## Step R3 — Write the derivation

```nix
{ lib, rustPlatform, fetchFromGitHub }:
rustPlatform.buildRustPackage rec {
  pname = "<name>";
  version = "<version>";

  src = fetchFromGitHub {
    owner = "<owner>";
    repo = "<name>";
    tag = "v${version}";
    hash = "sha256-…";   # from `nix store prefetch-file --json --unpack <tarball>`
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

Caveat if you must use `cargoHash` (no committed lockfile and cannot generate one):
fill `cargoHash = lib.fakeHash;`, build once, read the `got:` hash from the mismatch error,
paste it back. But in this environment the `403` will block that path — prefer `cargoLock`.

---

## Step R4 — Verify

Same standalone build as SKILL.md Step 7:
```
nix-build -E 'let p = import <nixpkgs> {}; in p.callPackage ./packages/<name>.nix {}'
./result/bin/<name> --version
rm -f result
```
The build runs the crate's `cargoCheckHook` (its test suite) — a clean pass confirms the
vendored crates and toolchain are correct. Then return to SKILL.md Step 5.