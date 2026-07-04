{ pkgs, ...}:
{
  home.packages = with pkgs; [
    beamPackages.erlang
    beamPackages.elixir
    rebar3
    gleam
  ];
}
