{ flake, ... }:
let
  inherit (flake) config inputs;
  inherit (inputs) self;
in
{
  imports = [
    {
      # For home-manager to work.
      users.users.${flake.config.people.myself} = {
        home = "/Users/${flake.config.people.myself}";
      };
      home-manager.users.${config.people.myself} = { };
      home-manager.useGlobalPkgs = true;
      home-manager.sharedModules = [
        self.homeModules.default
        self.homeModules.darwin-only
      ];
    }
    self.nixosModules.common
  ];
}
