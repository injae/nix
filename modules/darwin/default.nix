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
      users.users.${config.people.myself} = {
        home = "/Users/${config.people.myself}";
      };
      home-manager.users.${config.people.myself} = { };
      home-manager.useGlobalPkgs = true;
      home-manager.sharedModules = [
        self.homeModules.default
        self.homeModules.darwin-only
      ];
    }
  ]
  ++ (with builtins; map (fn: ./${fn}) (filter (fn: !(elem fn exclude)) (attrNames (readDir ./.))));
}
