#!/usr/bin/env bash
# SessionStart: reload direnv only if .envrc exists and not already loaded
[ -f .envrc ] || exit 0
if direnv status 2>/dev/null | grep -q "RC not loaded"; then
    direnv reload
fi