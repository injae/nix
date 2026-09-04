use_flake_exclude_git() {
    local flake=${1:-$FLAKE_TARGET}
    if [ -z "$flake" ]; then
        flake="."
    fi
    local paths=(flake.nix flake.lock)
    [ -e nix ] && paths+=(nix)
    local -x DIRENV_LOG_FORMAT=""
    local -x NIX_CONFIG="access-tokens = github.com=$(gh auth token)"
    git add "${paths[@]}"
    use flake $flake --impure
    git reset -q "${paths[@]}"
}
