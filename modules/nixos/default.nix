# Configuration common to all Linux systems
{
  flake,
  pkgs,
  ...
}:

let
  inherit (flake) config inputs;
  inherit (inputs) self;
  user = config.people.myself;
in
{
  imports = [
    {
      users.users.${user} = {
        isNormalUser = true;
        shell = pkgs.zsh;
        extraGroups = [
          "wheel"
          "networkmanager"
          "docker"
          "incus-admin"
        ];
      };
      home-manager.users.${user} = { };
      home-manager.sharedModules = [
        self.homeModules.default
        self.homeModules.linux-only
      ];
      home-manager.backupFileExtension = ".backup";
    }
    self.nixosModules.common
  ];
}
