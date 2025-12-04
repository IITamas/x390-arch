#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source ./helpers.sh
setup_user_vars

SWAY_DIR="$USER_HOME/.config/sway"
SCRIPT_DIR="$SWAY_DIR/scripts"

mkdir -p "$SWAY_DIR" "$SCRIPT_DIR" "$SWAY_DIR/help"

install_file ./config/sway-config "$SWAY_DIR/config" 644 || true
install_file ./config/generate-help.sh "$SCRIPT_DIR/generate-help.sh" 755 || true
install_file ./config/show-help.sh "$SCRIPT_DIR/show-help.sh" 755 || true
install_file ./config/monitor-manager.sh "$SCRIPT_DIR/monitor-manager.sh" 755 || true
install_file ./config/network-manager.sh "$SCRIPT_DIR/network-manager.sh" 755 || true
install_file ./config/toggle-keyboard.sh "$SCRIPT_DIR/toggle-keyboard.sh" 755 || true

"$SCRIPT_DIR/generate-help.sh" || true
sudo chown -R "$USER_NAME:$USER_NAME" "$SWAY_DIR" || true

echo "Sway configuration with keyboard layout support complete."