{ self, config, ... }:

{
  # Configuration common to all Linux systems
  flake = {
    nixosModules = {
      # NixOS modules that are known to work on nix-darwin.
      common.imports = [
        ./nix.nix
        ./caches
      ];

      my-home = {
        users.users.${config.people.myself}.isNormalUser = true;
        home-manager.useGlobalPkgs = true;
        home-manager.users.${config.people.myself} = {
          imports = [
            self.homeModules.common-linux
          ];
        };
      };

      default.imports = [
        self.nixosModules.home-manager
        self.nixosModules.my-home
        self.nixosModules.common
      ];
    };

    darwinModules = {
      my-home = {
        home-manager.useGlobalPkgs = true;
        home-manager.users.${config.people.myself} = {
          imports = [
            self.homeModules.common-darwin
          ];
        };
      };

      default.imports = [
        self.darwinModules_.home-manager
        self.darwinModules.my-home
        self.nixosModules.common
      ];
    };
  };
}
