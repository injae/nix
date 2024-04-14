{ self, inputs, ... }:
{
  flake = {
    homeModules = {
      common = {
        home.stateVersion = "23.11";
        imports = [
          inputs.nix-index-database.hmModules.nix-index
          inputs.agenix.homeManagerModules.age
          ({ pkgs, ... }: { home.packages = [ inputs.agenix.packages.${pkgs.system}.default ]; })
          ./programs/agenix
          ./programs/git
          ./programs/terminal
          ./programs/ssh
          ./programs/alacritty
          ./programs/aspell
          ./programs/emacs
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
