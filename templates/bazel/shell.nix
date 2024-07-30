{ pkgs
, buildFHSEnv
, mkShell
, hostPlatform
, writeShellScriptBin
}:
let
  # On darwin, we let bazelisk manage the bazel version since we actually need to run two
  # different versions thanks to aspect. Additionally bazelisk allows us to do
  # things like "bazel configure". So we just install a script called bazel
  # which calls bazelisk.
  #
  # Additionally bazel seems to break when CC and CXX is set to a nix managed
  # compiler on darwin. So the script unsets those.
  bazel-wrapper = writeShellScriptBin "bazel" ''
    unset TMPDIR TMP
    exec ${pkgs.bazelisk}/bin/bazelisk "$@"
  '';
  bazel-fhs = buildFHSEnv {
    name = "bazel";
    runScript = "bazel";
    targetPkgs = pkgs: (with pkgs; [
      bazel-wrapper
      zlib.dev
      stdenv
    ]);
    # unsharePid required to preserve bazel server between bazel invocations,
    # the rest are disabled just in case
    unsharePid = false;
    unshareUser = false;
    unshareIpc = false;
    unshareNet = false;
    unshareUts = false;
    unshareCgroup = false;
  };
in
mkShell.override { stdenv = if hostPlatform.isMacOS then pkgs.clang11Stdenv else pkgs.stdenv; } {
  nativeBuildInputs = with pkgs;
    [
      just

      bashInteractive
      bazel-fhs
      bazel-buildtools

      protobuf
      protoc-gen-rust
      protoc-gen-go

      go
      python310
    ];
  shellHook = ''
    alias python3=${pkgs.python310}
  '';
}
