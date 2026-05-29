#!/usr/bin/env bash
# FileChanged (**/.envrc) and CwdChanged: reload direnv when .envrc present
[ -f .envrc ] || exit 0
direnv reload