{ pkgs, ...}:
{
  home.packages = with pkgs; [
    erlang
    elixir
    rebar3
    gleam
  ];
}
