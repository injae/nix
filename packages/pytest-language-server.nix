{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "pytest-language-server";
  version = "0.22.3";

  src = fetchFromGitHub {
    owner = "bellini666";
    repo = "pytest-language-server";
    tag = "v${version}";
    hash = "sha256-sSmb06o/Znm9Qvla9KjuojRT1WW7Ho9DkZwC4w1HamY=";
  };

  cargoLock.lockFile = "${src}/Cargo.lock";

  meta = {
    description = "A blazingly fast Language Server Protocol implementation for pytest";
    homepage = "https://github.com/bellini666/pytest-language-server";
    license = lib.licenses.mit;
    mainProgram = "pytest-language-server";
  };
}
