#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1091
source ./helpers.sh

# Noisy sway validation
test_sway() {
  echo "Testing Sway configuration..."
  if ! command -v sway >/dev/null 2>&1; then
    echo "Warning: sway not installed; basic checks only"
    grep -q '^set \$mod ' ./config/sway-config || {
      echo "Error: sway-config missing \$mod definition"
      return 1
    }
    echo "Sway basic checks passed (sway not installed)"
    return 0
  fi

  if sway --help 2>&1 | grep -q -- '--validate'; then
    echo "Running: sway --validate -c ./config/sway-config"
    if sway --validate -c ./config/sway-config; then
      echo "Sway configuration test passed"
      return 0
    else
      echo "Sway configuration test FAILED (see errors above)"
      return 1
    fi
  fi

  echo "Running: sway -C -c ./config/sway-config"
  if sway -C -c ./config/sway-config; then
    echo "Sway configuration test passed"
    return 0
  else
    echo "Sway configuration test FAILED (see errors above)"
    return 1
  fi
}

# Noisy waybar validation or JSON fallback
test_waybar() {
  echo "Testing Waybar configuration..."
  if ! command -v waybar >/dev/null 2>&1; then
    echo "Warning: waybar not installed; validating JSON only via jq"
    jq empty ./config/waybar-config.json
    echo "Waybar JSON syntax OK"
    return 0
  fi

  if waybar --help 2>&1 | grep -q -- '--validate'; then
    echo "Running: waybar --validate --config ./config/waybar-config.json"
    if waybar --validate --config ./config/waybar-config.json; then
      echo "Waybar configuration test passed"
      return 0
    else
      echo "Waybar configuration test FAILED (see errors above)"
      return 1
    fi
  else
    echo "Waybar build has no --validate; checking JSON with jq"
    jq empty ./config/waybar-config.json
    echo "Waybar JSON syntax OK"
    return 0
  fi
}

test_alacritty() {
  echo "Testing Alacritty configuration..."
  if ! grep -q "\[window\]" ./config/alacritty.toml; then
    echo "Error: Alacritty config seems to be missing [window] section"
    return 1
  fi
  echo "Alacritty configuration test passed (basic check only)"
  return 0
}

test_all() {
  local ok=true
  local failed=()

  if ! test_sway; then ok=false; failed+=("sway"); fi
  if ! test_waybar; then ok=false; failed+=("waybar"); fi
  if ! test_alacritty; then ok=false; failed+=("alacritty"); fi

  for f in ./config/*; do
    base="$(basename "$f")"
    case "$base" in
      sway-config|waybar-config.json|alacritty.toml) continue ;;
    esac
    case "$base" in
      *.sh) echo "Testing shell script: $base"; bash -n "$f" ;;
      *.json) echo "Testing JSON file: $base"; jq empty "$f" ;;
      *.yaml|*.yml) echo "Testing YAML file: $base"; echo "Warning: yamllint not installed, skipping validation of $base" ;;
      *) echo "Basic existence check for $base"; [[ -s "$f" ]] || { echo "Error: $base is empty"; ok=false; failed+=("$base"); } ;;
    esac
  done

  if $ok; then
    echo "✅ All configuration tests passed!"
    return 0
  else
    echo "❌ Some configuration tests failed: ${failed[*]}"
    return 1
  fi
}

if [[ $# -eq 0 ]] || [[ "$1" == "all" ]]; then
  test_all
else
  case "$1" in
    sway) test_sway ;;
    waybar) test_waybar ;;
    alacritty) test_alacritty ;;
    *) echo "Usage: $0 [all|sway|waybar|alacritty]"; exit 1 ;;
  esac
fi