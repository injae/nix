{ self, ... }:
let
  excludes = [
    "default.nix"
    "mac-app-util.nix"
    "darwin-packages.nix"
  ];
in
{
  flake = {
    homeModules = {
      common = {
        home.stateVersion = "24.11";
        imports =
          with builtins;
          map (fn: ./${fn}) (filter (fn: !(elem fn excludes)) (attrNames (readDir ./.)));
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
