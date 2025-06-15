{
  config,
  pkgs,
  lib,
  ...
}:
with lib;

let
  cfg = config.local.colima;
in
{
  options.local.colima = {
    enable = mkOption {
      description = "Enable colima service";
      default = false;
      type = types.bool;
    };
    customTemplates = mkOption {
      description = "The template to use for colima";
      type = lib.types.attrsOf (types.attrsOf types.anything);
      default = { };
    };
    arguments = mkOption {
      description = "colima start {arguments}";
      type = types.listOf types.str;
      default = [ ];
    };
  };
  config = mkIf cfg.enable ({
    home.packages = [
      pkgs.colima
      pkgs.lima
      pkgs.lima-additional-guestagents
    ];
    home.file = lib.mapAttrs' (name: value: {
      name = ".colima/_templates/${name}.yaml";
      value = {
        source = (pkgs.formats.yaml { }).generate name value;
      };
    }) cfg.customTemplates;
    launchd.agents.colima = {
      enable = cfg.enable;
      config = {
        KeepAlive = true;
        RunAtLoad = true;
        ProgramArguments = [
          "${pkgs.colima}/bin/colima"
          "start"
        ] ++ cfg.arguments;
      };
    };
  });
}
