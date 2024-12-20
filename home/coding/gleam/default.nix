{ ... }:
let
  exclude_modules = [
    "default.nix"
  ];
in
  {
    imports =
      with builtins;
         map
           (fn: ./${fn})
           (filter (fn: !(elem fn exclude_modules)) (attrNames (readDir ./.)));
  }
