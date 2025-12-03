#!/usr/bin/env bash
# Testing framework for configurations

# Exit on error, undefined variable, or pipe failure
set -euo pipefail

# Source helpers
source ./helpers.sh

# Initialize state if needed
if [[ ! -d ./.state ]]; then
  ./state.sh
fi

# Test Sway configuration
test_sway() {
  echo "Testing Sway configuration..."
  if ! command -v sway &>/dev/null; then
    echo "Warning: Sway not installed, can't fully validate config"
    # Basic syntax check
    if ! grep -q "set \$mod " ./config/sway-config; then
      echo "Error: Sway config appears to be missing essential components"
      return 1
    fi
  else
    # Use sway's built-in validator (the -C flag checks config)
    if ! SWAYSOCK=/tmp/test XDG_RUNTIME_DIR=/tmp sway -C -c ./config/sway-config; then
      echo "Error: Sway configuration is invalid"
      return 1
    fi
  fi
  echo "Sway configuration test passed"
  return 0
}

# Test Waybar configuration
test_waybar() {
  echo "Testing Waybar configuration..."
  if ! command -v waybar &>/dev/null; then
    echo "Warning: Waybar not installed, can't fully validate config"
    # Basic JSON validation
    if ! jq empty ./config/waybar-config.json 2>/dev/null; then
      echo "Error: Waybar config is not valid JSON"
      return 1
    fi
  else
    # Use waybar's built-in validation
    if ! waybar --validate --config ./config/waybar-config.json; then
      echo "Error: Waybar configuration is invalid"
      return 1
    fi
  fi
  echo "Waybar configuration test passed"
  return 0
}

# Test Alacritty configuration
test_alacritty() {
  echo "Testing Alacritty configuration..."
  # Check if file exists and has valid TOML syntax
  # Unfortunately there's no direct TOML validator built into most systems
  # We'll do a basic check
  if ! grep -q "\[window\]" ./config/alacritty.toml; then
    echo "Error: Alacritty config seems to be missing essential sections"
    return 1
  fi
  echo "Alacritty configuration test passed (basic check only)"
  return 0
}

# Test all configurations with catch-all fallback
test_all() {
  local all_passed=true
  local failed_tests=()
  
  echo "Testing all configurations..."
  
  # Sway
  if ! test_sway; then
    all_passed=false
    failed_tests+=("sway")
  fi
  
  # Waybar
  if ! test_waybar; then
    all_passed=false
    failed_tests+=("waybar")
  fi
  
  # Alacritty
  if ! test_alacritty; then
    all_passed=false
    failed_tests+=("alacritty")
  fi
  
  # Catch-all test for remaining config files
  for config_file in ./config/*; do
    local basename=$(basename "$config_file")
    
    # Skip already tested configs
    if [[ "$basename" == "sway-config" ]] || 
       [[ "$basename" == "waybar-config.json" ]] || 
       [[ "$basename" == "alacritty.toml" ]]; then
      continue
    fi
    
    # Basic syntax checks based on file type
    case "$basename" in
      *.sh)
        echo "Testing shell script: $basename"
        if ! bash -n "$config_file"; then
          echo "Error: Shell script $basename has syntax errors"
          all_passed=false
          failed_tests+=("$basename")
        fi
        ;;
      *.json)
        echo "Testing JSON file: $basename"
        if ! jq empty "$config_file" 2>/dev/null; then
          echo "Error: JSON file $basename is not valid"
          all_passed=false
          failed_tests+=("$basename")
        fi
        ;;
      *.yaml|*.yml)
        echo "Testing YAML file: $basename"
        if command -v yamllint &>/dev/null; then
          if ! yamllint -d relaxed "$config_file"; then
            echo "Error: YAML file $basename is not valid"
            all_passed=false
            failed_tests+=("$basename")
          fi
        else
          echo "Warning: yamllint not installed, skipping validation of $basename"
        fi
        ;;
      *.conf|*.toml)
        echo "Basic existence check for $basename"
        if [[ ! -s "$config_file" ]]; then
          echo "Error: Configuration file $basename is empty"
          all_passed=false
          failed_tests+=("$basename")
        fi
        ;;
    esac
  done
  
  if $all_passed; then
    echo "✅ All configuration tests passed!"
    return 0
  else
    echo "❌ Some configuration tests failed: ${failed_tests[*]}"
    return 1
  fi
}

# Test a specific component or all
if [[ $# -eq 0 ]]; then
  test_all
else
  case "$1" in
    sway) test_sway ;;
    waybar) test_waybar ;;
    alacritty) test_alacritty ;;
    all) test_all ;;
    *)
      echo "Unknown component: $1"
      echo "Usage: $0 [sway|waybar|alacritty|all]"
      exit 1
      ;;
  esac
fi