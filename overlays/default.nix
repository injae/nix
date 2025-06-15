{ flake, ... }:

# get url from https://lazamar.co.uk/nix-versions/?channel=nixpkgs-unstable&package=
# or           https://history.nix-packages.com/search?search=
# get sha256 nix-prefetch-url
let
  inherit (flake) inputs;
  inherit (inputs) self;
  packages = self + /packages;
  #  version-overlay =
  #    { rev, sha256 }:
  #    import
  #      (self.fetchFromGitHub {
  #        owner = "NixOS";
  #        repo = "nixpkgs";
  #        inherit rev sha256;
  #      })
  #      {
  #        inherit (self) system;
  #        config.allowUnfree = true;
  #      };
  #
in
self: super: {
  #imports = [
  #  ./version-overlays
  #];
  #nuenv = (inputs.nuenv.overlays.nuenv self super).nuenv;
  mov2gif = self.callPackage "${packages}/mov2gif.nix" { };
  img2webp = self.callPackage "${packages}/img2webp.nix" { };
  dl-yt = self.callPackage "${packages}/dl-yt.nix" { };
  dl-yt-mp3 = self.callPackage "${packages}/dl-yt-mp3.nix" { };
}
