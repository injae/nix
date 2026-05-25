{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
let
  cfg = config.local.llama-cpp;

  serveModel = findFirst (m: m.name == cfg.serve) null cfg.models;

  startScript = pkgs.writeShellScript "llama-server-start" (
    ''
      set -euo pipefail
      mkdir -p "${cfg.modelsDir}"
    ''
    + concatMapStrings (m: ''
      if [ ! -f "${cfg.modelsDir}/${m.filename}" ]; then
        ${
          if m.url != null then
            ''
              echo "Downloading ${m.name}..."
              ${pkgs.curl}/bin/curl -L --progress-bar \
                -o "${cfg.modelsDir}/${m.filename}.part" \
                "${m.url}"
              rm -rf "${cfg.modelsDir}/${m.filename}"
              mv "${cfg.modelsDir}/${m.filename}.part" "${cfg.modelsDir}/${m.filename}"
            ''
          else
            ''
              echo "Model file missing: ${cfg.modelsDir}/${m.filename}" >&2
              exit 1
            ''
        }
      fi
    '') cfg.models
    + ''
      exec ${cfg.package}/bin/llama-server \
        --model "${cfg.modelsDir}/${serveModel.filename}" \
        --host "${cfg.host}" \
        --port "${toString cfg.port}" \
        --n-gpu-layers "${toString cfg.gpuLayers}" \
        --ctx-size "${toString cfg.ctxSize}" \
        ${concatStringsSep " \\\n  " cfg.extraArgs}
    ''
  );
in
{
  options = {
    local.llama-cpp = {
      enable = mkOption {
        description = "Enable llama-server service";
        default = false;
        type = types.bool;
      };

      package = mkOption {
        type = types.package;
        default = pkgs.llama-cpp;
        defaultText = literalExpression "pkgs.llama-cpp";
      };

      modelsDir = mkOption {
        type = types.str;
        description = "Directory to store GGUF model files.";
      };

      models = mkOption {
        type = types.listOf (
          types.submodule {
            options = {
              name = mkOption {
                type = types.str;
                description = "Logical model name.";
              };
              url = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = "Download URL (HuggingFace etc). Null = file must already exist.";
              };
              filename = mkOption {
                type = types.str;
                description = "Filename inside modelsDir.";
              };
            };
          }
        );
        default = [ ];
      };

      serve = mkOption {
        type = types.str;
        description = "Name of model (from models list) to serve.";
      };

      host = mkOption {
        type = types.str;
        default = "127.0.0.1";
      };

      port = mkOption {
        type = types.int;
        default = 8080;
      };

      gpuLayers = mkOption {
        type = types.int;
        default = 99;
        description = "Layers to offload to GPU (99 = all for Metal).";
      };

      ctxSize = mkOption {
        type = types.int;
        default = 0;
        description = "Context size (0 = read from model metadata).";
      };

      extraArgs = mkOption {
        type = types.listOf types.str;
        default = [ ];
      };

      environmentVariables = mkOption {
        type = types.attrsOf types.str;
        default = { };
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = serveModel != null;
        message = "local.llama-cpp.serve = \"${cfg.serve}\" not found in models list.";
      }
    ];

    environment.systemPackages = [ cfg.package ];

    launchd.user.agents.llama-server = {
      path = [ config.environment.systemPath ];
      serviceConfig = {
        KeepAlive = true;
        RunAtLoad = true;
        ProgramArguments = [
          "${pkgs.bash}/bin/bash"
          "${startScript}"
        ];
        EnvironmentVariables = cfg.environmentVariables;
        StandardOutPath = "/tmp/llama-server.log";
        StandardErrorPath = "/tmp/llama-server.log";
      };
    };
  };
}