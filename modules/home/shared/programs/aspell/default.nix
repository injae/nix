{ pkgs, ... }:
let
  # aspell ships no Korean dictionary, so Korean spell checking goes through
  # hunspell instead.
  hunspell = pkgs.hunspell.withDicts (dicts: with dicts; [ en_US ko_KR ]);
in
{
  home.packages = [
    hunspell
    #pkgs.aspell
    (pkgs.aspellWithDicts (dicts: with dicts; [ en ]))
  ];

  # Enchant looks for hunspell dictionaries under the "hunspell" subdirectory of
  # every XDG data directory, and the per-user profile links only a fixed set of
  # share subdirectories, which does not include that one. Naming the package
  # here is what makes its dictionaries reachable; `config.home.path' would be
  # the obvious source but recurses back into `home.packages'.
  home.sessionVariables.XDG_DATA_DIRS = "${hunspell}/share\${XDG_DATA_DIRS:+:$XDG_DATA_DIRS}";

  #home.file.".aspell.conf" = {
  #  text = ''data-dir ${pkgs.aspellDicts.en}'';
  #};
}
