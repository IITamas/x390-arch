#!/usr/bin/env bash
# Sway configuration with US-Hungarian keyboard switching

# Load helper functions
source ./helpers.sh

# Setup user variables
setup_user_vars

# Create Sway directories and scripts
SWAY_DIR="$USER_HOME/.config/sway"
SCRIPT_DIR="$SWAY_DIR/scripts"

ensure_dir "$SWAY_DIR" "$USER_NAME:$USER_NAME"
ensure_dir "$SCRIPT_DIR" "$USER_NAME:$USER_NAME"
ensure_dir "$SWAY_DIR/help" "$USER_NAME:$USER_NAME"

# Copy Sway config file
backup_file "$SWAY_DIR/config"
cp ./config/sway-config "$SWAY_DIR/config"

# Copy and set up scripts
cp ./config/generate-help.sh "$SCRIPT_DIR/generate-help.sh"
chmod +x "$SCRIPT_DIR/generate-help.sh"

cp ./config/show-help.sh "$SCRIPT_DIR/show-help.sh"
chmod +x "$SCRIPT_DIR/show-help.sh"

cp ./config/monitor-manager.sh "$SCRIPT_DIR/monitor-manager.sh"
chmod +x "$SCRIPT_DIR/monitor-manager.sh"

cp ./config/network-manager.sh "$SCRIPT_DIR/network-manager.sh"
chmod +x "$SCRIPT_DIR/network-manager.sh"

cp ./config/toggle-keyboard.sh "$SCRIPT_DIR/toggle-keyboard.sh"
chmod +x "$SCRIPT_DIR/toggle-keyboard.sh"

# Generate the initial keybinding help
"$SCRIPT_DIR/generate-help.sh"

chown -R "$USER_NAME:$USER_NAME" "$SWAY_DIR"

echo "Sway configuration with keyboard layout support complete."