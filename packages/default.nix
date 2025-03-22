{
  flake,
  pkgs,
  ...
}:
# get url from https://lazamar.co.uk/nix-versions/?channel=nixpkgs-unstable&package=
# or           https://history.nix-packages.com/search?search=
# get sha256 nix-prefetch-url
let
  version-overlay =
    { rev, sha256 }:
    import
      (pkgs.fetchFromGitHub {
        owner = "NixOS";
        repo = "nixpkgs";
        inherit rev sha256;
      })
      {
        inherit (pkgs) system;
        config.allowUnfree = true;
      };
in
self: super: {
  mov2gif = self.callPackage ./mov2gif.nix { };
  img2webp = self.callPackage ./img2webp.nix { };
  dl-yt = self.callPackage ./dl-yt.nix { };
  dl-yt-mp3 = self.callPackage ./dl-yt-mp3.nix { };
  #bazel7 = self.callPackage ./bazel_7.nix { version = "7.0.0"; };
  #terraform_1_7_5 =
  #  (version-overlay {
  #    rev = "336eda0d07dc5e2be1f923990ad9fdb6bc8e28e3";
  #    sha256 = "sha256-mYJwTy2TNTOXbxVtmhXDv98F2ORhxRzL1S6yw1+1G20=";
  #  }).terraform;
}
