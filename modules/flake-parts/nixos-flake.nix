{ inputs, ... }:
{
  imports = [
    inputs.nixos-unified.flakeModules.default
    inputs.nixos-unified.flakeModules.autoWire
    #../../templates
  ];
  perSystem =
    { self', ... }:
    {
      packages.default = self'.packages.activate;

      # Flake inputs we want to update periodically
      # Run: `nix run .#update`.
      nixos-unified = {
        primary-inputs = [
          "nixpkgs"
          "home-manager"
          "nix-darwin"
          "nixos-unified"
          "nix-index-database"
          "rust-overlay"
          "emacs-overlay"
          "emacs-lsp-booster"
        ];
      };
    };
}
