#!/bin/bash
# Bash permission hook: Allow most commands, ask for dangerous ones and non-tmp deletions

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

# Helper function to split command by common separators
split_commands() {
  local cmd="$1"
  # Split by &&, ||, ;, and | (pipe) - replace with newlines
  echo "$cmd" | sed 's/&&/\n/g; s/||/\n/g; s/;/\n/g; s/|/\n/g'
}

# Read JSON input from stdin
read -r json_input

log_debug "Hook invoked at $(date)"
log_debug "Input: $json_input"

# Extract command from the input
command=$(echo "$json_input" | jq -r '.tool_input.command // empty')
log_debug "Command: $command"

# Strip heredoc content from command for pattern checking
# This prevents false positives from heredoc body content
command_for_checks="$command"
if echo "$command" | grep -qE "<<"; then
  command_for_checks=$(echo "$command" | sed -n '1,/<<.*$/p' | head -1)
  log_debug "Heredoc detected, using command part for checks: $command_for_checks"
fi

# Check for shell profile modifications (but allow /tmp and /var/tmp redirections)
if echo "$command_for_checks" | grep -qE ">.*\.(bash|zsh)" && ! echo "$command_for_checks" | grep -qE ">\s*/tmp/|>\s*/var/tmp/"; then
  log_debug "Shell profile modification detected, asking for permission"
  respond "ask" "Shell profile modification detected"
fi

# Check for shell profile modifications via sed/awk/perl and other text editors
if echo "$command_for_checks" | grep -qE "(sed|awk|perl|ex|ed|vi|vim|nano|emacs).*\.(bashrc|zshrc|bash_profile|zprofile|profile)(\s|$)"; then
  log_debug "Shell profile modification via text processing detected, asking for permission"
  respond "ask" "Shell profile modification detected"
fi

# Check for rm commands - auto-allow tmp deletions, prompt for others
while IFS= read -r cmd; do
  cmd=$(echo "$cmd" | xargs)
  if echo "$cmd" | grep -qE "^\s*rm\s+"; then
    log_debug "Deletion command detected in: $cmd"
    if echo "$cmd" | grep -qE "rm\s+(-[a-z]+\s+)*/tmp/|rm\s+(-[a-z]+\s+)*[^/]*\.tmp(\s|$)|rm\s+(-[a-z]+\s+)*/var/tmp/"; then
      log_debug "Deleting tmp file(s) in this command"
    else
      log_debug "Non-tmp file deletion detected, asking for permission"
      respond "ask" "Non-temp file deletion requires confirmation"
    fi
  fi
done <<< "$(split_commands "$command_for_checks")"

# Check for dangerous command patterns (rm handled separately above)
DANGEROUS_PATTERN="^\s*(sudo\s+|git\s+push\s+(--force|-f)|git\s+reset\s+--hard|git\s+clean\s+-f|mkfs\s+|dd\s+if=.*of=/dev|chmod\s+-R\s+777|chown\s+-R|kill\s+-9\s+1|reboot\s*$|shutdown\s*$|halt\s*$|poweroff\s*$)"

while IFS= read -r cmd; do
  cmd=$(echo "$cmd" | xargs)
  if echo "$cmd" | grep -qE "$DANGEROUS_PATTERN"; then
    log_debug "Dangerous command detected in: $cmd"
    respond "ask" "Dangerous command detected"
  fi
done <<< "$(split_commands "$command_for_checks")"

# Check if executing a script and scan its content for dangerous patterns
# Strip leading parentheses and whitespace to handle subshell patterns like (exec script.sh)
command_stripped=$(echo "$command" | sed 's/^[[:space:]]*(\+[[:space:]]*//')

# Match shell commands, sourcing, exec, env wrappers, or direct script execution
if echo "$command_stripped" | grep -qE "^\s*(bash|sh|zsh|ksh|csh|tcsh|fish|source|exec|env|/bin/(bash|sh|zsh|ksh|csh|tcsh|fish))\s+" || echo "$command_stripped" | grep -qE "^\s*\.\s+" || echo "$command_stripped" | grep -qE "^\s*(\./|[~/])"; then
  log_debug "Script execution detected"

  # Extract script filename
  if echo "$command_stripped" | grep -qE "^\s*\.\s+"; then
    # Dot sourcing: ". script.sh"
    script_file=$(echo "$command_stripped" | awk '{print $2}')
  elif echo "$command_stripped" | grep -qE "^\s*env\s+"; then
    # env wrapper: skip env and its flags, then extract script
    script_file=$(echo "$command_stripped" | awk '{
      for (i = 2; i <= NF; i++) {
        if ($i !~ /^-/) {
          # Check if this is a shell command, if so get next arg
          if ($i ~ /^(bash|sh|zsh|ksh|csh|tcsh|fish|\/bin\/(bash|sh|zsh|ksh|csh|tcsh|fish))$/) {
            for (j = i + 1; j <= NF; j++) {
              if ($j !~ /^-/) {
                print $j
                exit
              }
            }
          } else {
            # Not a shell command, treat as direct script execution
            print $i
            exit
          }
        }
      }
    }')
  elif echo "$command_stripped" | grep -qE "^\s*(bash|sh|zsh|ksh|csh|tcsh|fish|source|exec|/bin/(bash|sh|zsh|ksh|csh|tcsh|fish))\s+"; then
    # Explicit shell/exec command: skip command and flags
    script_file=$(echo "$command_stripped" | awk '{
      for (i = 2; i <= NF; i++) {
        if ($i !~ /^-/) {
          print $i
          exit
        }
      }
    }')
  else
    # Direct script execution (./script or /path/script or ~/script)
    script_file=$(echo "$command_stripped" | awk '{print $1}')
  fi
  log_debug "Extracted script file: $script_file"

  # Resolve relative script paths using working directory from context
  if [ ! -f "$script_file" ]; then
    working_dir=$(echo "$json_input" | jq -r '.context.cwd // empty')
    if [ -n "$working_dir" ] && [ -f "$working_dir/$script_file" ]; then
      script_file="$working_dir/$script_file"
      log_debug "Resolved to: $script_file"
    fi
  fi

  # Scan script file for dangerous patterns
  if [ -f "$script_file" ] && [ -r "$script_file" ]; then
    log_debug "Scanning script file for dangerous patterns"
    dangerous_lines=$(grep -nE "$DANGEROUS_PATTERN" "$script_file" 2>/dev/null || true)
    if [ -n "$dangerous_lines" ]; then
      log_debug "Script contains dangerous commands: $dangerous_lines"
      # Format: "3:sudo apt-get update; 4:git push --force origin master;"
      formatted_lines=$(echo "$dangerous_lines" | head -5 | while IFS= read -r line; do
        line_num=$(echo "$line" | cut -d: -f1)
        line_content=$(echo "$line" | cut -d: -f2- | xargs)
        printf "%s:%s; " "$line_num" "$line_content"
      done)
      respond "ask" "Script contains dangerous commands: $formatted_lines"
    fi
    log_debug "Script is safe, allowing execution"
  else
    log_debug "Script file not found or not readable: $script_file, allowing anyway"
  fi
fi

# All other commands are safe
log_debug "Safe command, allowing"
respond "allow" "Safe command auto-approved"
