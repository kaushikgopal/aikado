#!/bin/bash
# MCP tool permission hook: Auto-allow all MCP tool calls

DEBUG="${CLAUDE_SELECTIVE_BYPASS_DEBUG:-false}"
LOG_FILE=~/.claude/selective-bypass-debug.log

# Helper function for debug logging
log_debug() {
  [ "$DEBUG" = true ] && echo "$1" >> "$LOG_FILE"
}

# Helper function for hook responses
respond() {
  local decision="$1"
  local reason="$2"
  echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"$decision\",\"permissionDecisionReason\":\"$reason\"}}"
  exit 0
}

# Read JSON input from stdin
read -r json_input

log_debug "MCP hook invoked at $(date)"
log_debug "Input: $json_input"

# Extract tool name
tool_name=$(echo "$json_input" | jq -r '.tool_name // empty')
log_debug "MCP Tool: $tool_name"

# Auto-allow all MCP tool calls
log_debug "MCP tool auto-approved"
respond "allow" "MCP tool auto-approved"
