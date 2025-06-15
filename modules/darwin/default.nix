{ flake, ... }:
let
  inherit (flake) config inputs;
  inherit (inputs) self;
  exclude = [
    "default.nix"
  ];
in
{
  imports = [
    {
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
  ] ++ (with builtins; map (fn: ./${fn}) (filter (fn: !(elem fn exclude)) (attrNames (readDir ./.))));
}
