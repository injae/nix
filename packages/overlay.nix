{ flake, system, ... }:

# get url from https://lazamar.co.uk/nix-versions/?channel=nixpkgs-unstable&package=
# or           https://history.nix-packages.com/search?search=
# get sha256 nix-prefetch-url
self: super:
let
  lib = super.lib;
  version-overlay = { rev, sha256 }:
    import (super.fetchFromGitHub { owner = "NixOS"; repo = "nixpkgs"; inherit rev sha256; })
      { inherit system; config.allowUnfree = true; };
in
{
  #bazel_7_1_2 = (super.bazel_7.override { version = "7.1.2"; }).overrideAttrs
  #  (rec {
  #    version = "7.1.2";
  #    src = super.fetchurl {
  #      url = "https://github.com/bazelbuild/bazel/releases/download/${version}/bazel-${version}-dist.zip";
  #      hash = "sha256-nPbtIxnIFpGdlwFe720MWULNGu1I4DxzuggV2VPtYas=";
  #    };
  #    lockfile = super.fetchurl {
  #      url = "https://raw.githubusercontent.com/bazelbuild/bazel/release-${version}/MODULE.bazel.lock";
  #      sha256 = "sha256:0xjxszkgxab2gp9pqy6r7bpf3abqvmrv4gkcdlnwdi0w7j6w986f";
  #    };
  #  });
  # example
  #terraform_1_7_5 = (version-overlay {
  #  rev = "336eda0d07dc5e2be1f923990ad9fdb6bc8e28e3";
  #  sha256 = "sha256-mYJwTy2TNTOXbxVtmhXDv98F2ORhxRzL1S6yw1+1G20=";
  #}).terraform;

  #mise = flake.inputs.mise.packages.${system}.mise;
  # fuckport = self.callPackage ./fuckport.nix { };
}
