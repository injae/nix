{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
let
  cfg = config.local.ollama;
in
{
  options = {
    local.ollama = {
      enable = mkOption {
        description = "Enable ollama service";
        default = false;
        type = types.bool;
      };
      package = mkOption {
        type = types.package;
        default = pkgs.ollama;
        defaultText = literalExpression "pkgs.ollama";
        description = "This option specifies the ollama package to use.";
      };

      ollamaHost = mkOption {
        description = "The host address for the ollama service";
        default = "127.0.0.1:11434";
        type = types.str;
      };

      models = mkOption {
        type = types.nullOr types.path;
        default = null;
        example = "/path/to/ollama/models";
        description = ''
          The directory that the ollama service will read models from and download new models to.
        '';
      };

      environmentVariables = mkOption {
        type = types.attrsOf types.str;
        default = { };
        example = {
          OLLAMA_LLM_LIBRARY = "cpu";
          HIP_VISIBLE_DEVICES = "0,1";
        };
        description = ''
          Set arbitrary environment variables for the ollama service.

          Be aware that these are only seen by the ollama server (launchd daemon),
          not normal invocations like `ollama run`.
          Since `ollama run` is mostly a shell around the ollama server, this is usually sufficient.
        '';
      };

      modelFiles = mkOption {
        type = types.attrsOf types.lines;
        default = { };
        example = {
          qwen3-coder = ''
            FROM qwen3:30b
            PARAMETER num_ctx 16384
          '';
        };
        description = ''
          Custom Ollama models to create at startup from Modelfile content.
          Each attribute maps a model name to its Modelfile content.
          Models are created (or updated) before preloading.
        '';
      };

      preloadModels = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [ "qwen3:30b" ];
        description = ''
          Models to preload into memory when the ollama service starts.
          A separate launchd agent polls until ollama is ready, then loads
          each model with keep_alive=-1 so they remain in memory indefinitely.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    # https://github.com/LnL7/nix-darwin/pull/972/files
    environment.systemPackages = [ cfg.package ];

    launchd.user.agents.ollama-preload =
      mkIf (cfg.preloadModels != [ ] || cfg.modelFiles != { })
        {
          path = [ config.environment.systemPath ];
          serviceConfig = {
            RunAtLoad = true;
            ProgramArguments = [
              "${pkgs.bash}/bin/bash"
              "-c"
              (
                ''
                  until ${pkgs.curl}/bin/curl -sf "http://${cfg.ollamaHost}/api/tags" > /dev/null 2>&1; do
                    sleep 2
                  done
                ''
                + lib.concatStrings (
                  lib.mapAttrsToList (name: content: ''
                    ${cfg.package}/bin/ollama create "${name}" -f "${pkgs.writeText "Modelfile-${name}" content}"
                  '') cfg.modelFiles
                )
                + lib.concatMapStrings (model: ''
                  ${pkgs.curl}/bin/curl -sf "http://${cfg.ollamaHost}/api/generate" \
                    -d '{"model":"${model}","keep_alive":-1}' > /dev/null 2>&1
                '') cfg.preloadModels
              )
            ];
            StandardOutPath = "/tmp/ollama-preload.log";
            StandardErrorPath = "/tmp/ollama-preload.log";
          };
        };

    launchd.user.agents.ollama = {
      path = [ config.environment.systemPath ];
      serviceConfig = {
        KeepAlive = true;
        RunAtLoad = true;
        ProgramArguments = [
          "${cfg.package}/bin/ollama"
          "serve"
        ];
        EnvironmentVariables =
          cfg.environmentVariables
          // {
            OLLAMA_HOST = cfg.ollamaHost;
          }
          // (optionalAttrs (cfg.models != null) {
            OLLAMA_MODELS = toString cfg.models;
          });
      };
    };
  };

}
