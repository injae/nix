{ flake, system, ... }:

# get url from https://lazamar.co.uk/nix-versions/?channel=nixpkgs-unstable&package=
# or           https://history.nix-packages.com/search?search=
self: super:
let
  version-overlay = { rev, sha256 }:
    import (super.fetchFromGitHub { owner = "NixOS"; repo = "nixpkgs"; inherit rev sha256; })
      { inherit system; config.allowUnfree = true; };
in
{
  # example
  #terraform_1_7_5 = (version-overlay {
  #  rev = "336eda0d07dc5e2be1f923990ad9fdb6bc8e28e3";
  #  sha256 = "sha256-mYJwTy2TNTOXbxVtmhXDv98F2ORhxRzL1S6yw1+1G20=";
  #}).terraform;

  # fuckport = self.callPackage ./fuckport.nix { };
}
