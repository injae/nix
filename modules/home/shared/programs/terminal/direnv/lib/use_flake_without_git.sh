use_flake_exclude_git() {
    local flake=${1:-$FLAKE_TARGET}
    if [ -z "$flake" ]; then
        flake="."
    fi
    git add flake.nix flake.lock nix
    use flake $flake --impure
    git reset flake.nix flake.lock nix
}
