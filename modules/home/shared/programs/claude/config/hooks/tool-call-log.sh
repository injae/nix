#!/usr/bin/env bash
# PostToolUse hook: log all tool calls to ~/.log/claude/tool-calls.log

mkdir -p ~/.log/claude
jq -r '["[", (now | strftime("%Y-%m-%dT%H:%M:%SZ")), "] ", .tool_name, ": ", (.tool_input | tostring)] | join("")' \
  >> ~/.log/claude/tool-calls.log 2>/dev/null || true
