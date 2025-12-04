#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source ./helpers.sh
setup_user_vars

WB_DIR="$USER_HOME/.config/waybar"
mkdir -p "$WB_DIR" "$WB_DIR/state"

echo '{"layout": "us"}' > "$WB_DIR/state/keyboard.json" || true
install_file ./config/waybar-config.json "$WB_DIR/config" 644 || true
install_file ./config/waybar-style.css "$WB_DIR/style.css" 644 || true

sudo chown -R "$USER_NAME:$USER_NAME" "$WB_DIR" || true
echo "Waybar configuration with keyboard layout indicator complete."