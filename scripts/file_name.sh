#!/usr/bin/env bash
name=$(basename "$1")
echo "${name%.*}"
