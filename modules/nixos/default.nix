# Configuration common to all Linux systems
{ flake, pkgs, ... }:
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
        isNormalUser = true;
        shell = pkgs.zsh;
        extraGroups = [
          "wheel"
          "networkmanager"
          "docker"
          "incus-admin"
        ];
      };
      home-manager.users.${config.people.myself} = { };
      home-manager.sharedModules = [
        self.homeModules.default
        self.homeModules.linux-only
      ];
      home-manager.backupFileExtension = ".backup";
    }
  ]
  ++ (with builtins; map (fn: ./${fn}) (filter (fn: !(elem fn exclude)) (attrNames (readDir ./.))));
}
