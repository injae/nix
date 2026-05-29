#!/usr/bin/env bash
# SessionStart: reload direnv only if .envrc exists and not already loaded
[ -f .envrc ] || exit 0
direnv status 2>/dev/null | grep -q "RC not loaded" && direnv reload