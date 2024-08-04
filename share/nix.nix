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

  # but NIX_PATH is still used by many useful tools, so we set it to the same value as the one used by this flake.
  # Make `nix repl '<nixpkgs>'` use the same nixpkgs as the one used by this flake.
  environment.etc."nix/inputs/nixpkgs".source = "${flake.inputs.nixpkgs}";

  nix =
    let
      nixpkgs = flake.inputs.nixpkgs;
    in
    {
      nixPath = [ "nixpkgs=${nixpkgs}" ]; # Enables use of `nix-shell -p ...` etc
      channel.enable = false; # remove nix-channel related tools & configs, we use flakes instead.
      registry.nixpkgs.flake = nixpkgs; # Make `nix shell` etc use pinned nixpkgs

      settings = {
        # https://github.com/NixOS/nix/issues/9574
        nix-path = lib.mkForce "nixpkgs=/etc/nix/inputs/nixpkgs";
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
