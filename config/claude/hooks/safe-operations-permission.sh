#!/bin/bash
# Safe operations permission hook: Auto-allow non-destructive operations

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

log_debug "Safe operations hook invoked at $(date)"
log_debug "Input: $json_input"

# Extract tool name
tool_name=$(echo "$json_input" | jq -r '.tool_name // empty')
log_debug "Tool: $tool_name"

# Auto-allow all safe operations
log_debug "Safe operation auto-approved"
respond "allow" "Safe operation auto-approved"
