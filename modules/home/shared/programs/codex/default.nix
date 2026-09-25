{ lib, pkgs, ... }:
let
  python = pkgs.python3.withPackages (ps: [ ps.tomlkit ]);
  managedConfig = (pkgs.formats.toml { }).generate "codex-config.toml" (
    import ./config.nix { inherit lib pkgs; }
  );
in
{
  home.file.".codex/AGENTS.md" = {
    source = ./config/AGENTS.md;
    force = true;
  };

  # Codex also writes project trust and TUI state here; keep those local values.
  home.activation.codexConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${python}/bin/python3 ${./merge-config.py} ${managedConfig}
  '';
}
