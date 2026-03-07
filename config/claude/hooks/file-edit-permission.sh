#!/bin/bash
# File edit permission hook: Auto-allow reads, configurable write behavior

MODE="${CLAUDE_SELECTIVE_BYPASS_MODE:-permissive}"
DEBUG="${CLAUDE_SELECTIVE_BYPASS_DEBUG:-false}"
LOG_FILE=~/.claude/selective-bypass-debug.log

log_debug() {
  [ "$DEBUG" = "true" ] && echo "$1" >> "$LOG_FILE"
}

respond() {
  local decision="$1"
  local reason="$2"
  echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"$decision\",\"permissionDecisionReason\":\"$reason\"}}"
  exit 0
}

read -r json_input

log_debug "File edit hook invoked at $(date) [MODE: $MODE]"
log_debug "Input: $json_input"

tool_name=$(echo "$json_input" | jq -r '.tool_name // empty')
file_path=$(echo "$json_input" | jq -r '.tool_input.file_path // empty')
log_debug "Tool: $tool_name, File path: $file_path"

# Always auto-allow Read/Glob/Grep operations
if [ "$tool_name" = "Read" ] || [ "$tool_name" = "Glob" ] || [ "$tool_name" = "Grep" ]; then
  log_debug "Read-only operation, auto-allowing"
  respond "allow" "Read-only operation auto-approved"
fi

# Check for shell profile modifications
if echo "$file_path" | grep -qE "\.(bashrc|zshrc|bash_profile|zprofile|profile)$|/\.bashrc$|/\.zshrc$|/\.bash_profile$|/\.zprofile$|/\.profile$"; then
  log_debug "Shell profile modification detected, asking for permission"
  respond "ask" "Shell profile modification requires confirmation"
fi

# Check if it's a tmp file
is_tmp=false
if echo "$file_path" | grep -qE "/tmp/|\.tmp$|/var/tmp/|\.swp$|\.swo$|\.cache/"; then
  is_tmp=true
fi

# Handle Write/Edit based on mode
if [ "$MODE" = "permissive" ]; then
  log_debug "Permissive mode: auto-allowing write/edit"
  respond "allow" "Write/edit auto-approved"
else
  if [ "$is_tmp" = true ]; then
    log_debug "Restrictive mode: tmp file, auto-allowing"
    respond "allow" "Temp file write auto-approved"
  else
    log_debug "Restrictive mode: non-tmp file, asking for permission"
    respond "ask" "Non-temp file write requires confirmation"
  fi
fi
