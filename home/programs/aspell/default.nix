{ pkgs, ... }:
{
  home.packages = with pkgs; [
    hunspell
    #aspell
    (aspellWithDicts (dicts: with dicts; [ en ]))
  ];

  #home.file.".aspell.conf" = {
  #  text = ''data-dir ${pkgs.aspellDicts.en}'';
  #};
}
