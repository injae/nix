{ self, inputs, ... }:
{
  flake = {
    homeModules = {
      common = {
        home.stateVersion = "23.11";
        imports = [
          inputs.nix-index-database.hmModules.nix-index
          inputs.lix-module.nixosModules.default
          inputs.sops-nix.homeManagerModules.sops
          ./programs/sops
          ./programs/aws
          ./programs/gcp
          ./programs/git
          ./programs/neovim
          ./programs/terminal
          ./programs/ssh
          ./programs/font
          ./programs/alacritty
          ./programs/aspell
          ./programs/container
          ./programs/emacs
          ./coding/nix
          ./coding/rust
          ./coding/python
          ./coding/golang
          ./coding/javascript
          ./coding/java
          ./coding/cpp
          ./coding/lua
          ./coding/terraform
          ./packages.nix
        ];
      };

      # home-manager config specific to NixOS
      common-linux = {
        imports = [
          self.homeModules.common
        ];
      };

      # home-manager config specifi to Darwin
      common-darwin = {
        imports = [
          self.homeModules.common
          ./mac-app-util.nix
          ./darwin-packages.nix
        ];
      };
    };
  };
}
