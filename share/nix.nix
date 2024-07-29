{ flake, pkgs, lib, ... }:

{
  nixpkgs = {
    config = {
      allowBroken = true;
      allowUnsupportedSystem = true;
      allowUnfree = true;
      #allowInsecure = false;
    };
    overlays = [
      flake.inputs.rust-overlay.overlays.default
      flake.inputs.emacs-overlay.overlays.default
      flake.inputs.emacs-lsp-booster.overlays.default
      (import ../packages/overlay.nix { inherit flake; inherit (pkgs) system; })
    ];
  };

  nix = {
    nixPath = [ "nixpkgs=${flake.inputs.nixpkgs}" ]; # Enables use of `nix-shell -p ...` etc
    registry.nixpkgs.flake = flake.inputs.nixpkgs; # Make `nix shell` etc use pinned nixpkgs
    settings = {
      max-jobs = "auto";

      system-features = [ ] ++ (if pkgs.stdenv.isDarwin then [
        "apple-virt"
        "nixos-test"
      ] else [ "kvm" ]);

      experimental-features = [ "nix-command" "flakes" "repl-flake" ];
      # I don't have an Intel mac.
      extra-platforms = lib.mkIf pkgs.stdenv.isDarwin "aarch64-darwin x86_64-darwin";
      # Nullify the registry for purity.
      flake-registry = builtins.toFile "empty-flake-registry.json" ''{"flakes":[],"version":2}'';
      trusted-users = [
        "root"
        (if pkgs.stdenv.isDarwin
        then flake.config.people.myself #"@admin"
        else "@wheel")
      ];
    };
  };
}
