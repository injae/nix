{ ... }:
{
  imports =
    with builtins;
         map
           (fn: ./${fn})
           (filter (fn: !(elem fn ["default.nix"])) (attrNames (readDir ./.)));
}
