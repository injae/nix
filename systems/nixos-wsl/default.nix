{ pkg, flake, ... }:
let
  inherit (flake) inputs;
  inherit (inputs) self;
in
{
  imports = [
    inputs.nixos-wsl.nixosModules.default
    self.nixosModules.default
  ];
  system.stateVersion = "24.05";
  wsl.enable = true;
}
  
