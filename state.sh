#!/usr/bin/env bash
# State tracking system for configurations

# Exit on error, undefined variable, or pipe failure
set -euo pipefail

STATE_DIR="./.state"
APPLIED_DIR="$STATE_DIR/applied"
ROLLBACK_DIR="$STATE_DIR/rollback"

# Initialize state directory structure
init_state() {
  mkdir -p "$APPLIED_DIR" "$ROLLBACK_DIR"
  echo "State tracking system initialized."
}

# Track that a configuration has been applied
track_applied() {
  local config="$1"
  local target="$2"
  local timestamp="$(date +%s)"
  local checksum=""
  
  # Calculate checksum of current config file
  if [[ -f "$config" ]]; then
    checksum=$(sha256sum "$config" | cut -d ' ' -f 1)
  else
    echo "Error: Config file $config does not exist"
    return 1
  fi
  
  # Save previous version if it exists
  if [[ -f "$target" ]] && [[ -f "$APPLIED_DIR/$(basename "$target")" ]]; then
    cp "$APPLIED_DIR/$(basename "$target")" "$ROLLBACK_DIR/$(basename "$target").$(date +%s)"
  fi
  
  # Record application in state file
  echo "$timestamp,$checksum,$target" > "$APPLIED_DIR/$(basename "$target")"
  echo "Tracked state for $(basename "$target")"
}

# Check if configuration needs to be updated based on state
needs_update() {
  local config="$1"
  local target="$2"
  
  # If target doesn't exist, needs update
  if [[ ! -f "$target" ]]; then
    return 0 # true, needs update
  fi
  
  # If state doesn't exist, needs update
  if [[ ! -f "$APPLIED_DIR/$(basename "$target")" ]]; then
    return 0 # true, needs update
  fi
  
  # Get current checksum of config file
  local current_checksum=$(sha256sum "$config" | cut -d ' ' -f 1)
  
  # Get last applied checksum
  local last_checksum=$(cat "$APPLIED_DIR/$(basename "$target")" | cut -d ',' -f 2)
  
  # If checksums don't match or target differs from config, needs update
  if [[ "$current_checksum" != "$last_checksum" ]] || ! diff -q "$config" "$target" &>/dev/null; then
    return 0 # true, needs update
  fi
  
  return 1 # false, doesn't need update
}

# Rollback a configuration to its previous state
rollback() {
  local target="$1"
  local basename=$(basename "$target")
  
  # Find most recent rollback version
  local rollback_file=$(ls -t "$ROLLBACK_DIR/$basename."* 2>/dev/null | head -1)
  
  if [[ -z "$rollback_file" ]]; then
    echo "No rollback version available for $basename"
    return 1
  fi
  
  # Create backup of current version
  if [[ -f "$target" ]]; then
    cp "$target" "$target.failed.$(date +%s)"
  fi
  
  # Apply rollback
  local target_dir=$(dirname "$target")
  mkdir -p "$target_dir"
  cp "$rollback_file" "$target"
  
  echo "Rolled back $basename to previous version"
  
  # Update state to reflect rollback
  local rollback_checksum=$(sha256sum "$target" | cut -d ' ' -f 1)
  local timestamp="$(date +%s)"
  echo "$timestamp,$rollback_checksum,$target" > "$APPLIED_DIR/$basename"
  
  return 0
}

# If run directly, initialize the state system
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  init_state
fi