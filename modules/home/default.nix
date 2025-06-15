{ ... }:
let
  excludes = [ ];
in
{
  home.stateVersion = "25.05";
  imports =
    with builtins;
    map (fn: ./shared/${fn}) (filter (fn: !(elem fn excludes)) (attrNames (readDir ./shared)));
}
