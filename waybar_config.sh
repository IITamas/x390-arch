#!/usr/bin/env bash
# Waybar configuration with keyboard layout indicator

# Load helper functions
source ./helpers.sh

# Setup user variables
setup_user_vars

# Configure waybar with keyboard layout indicator
WB_DIR="$USER_HOME/.config/waybar"
ensure_dir "$WB_DIR" "$USER_NAME:$USER_NAME"
ensure_dir "$WB_DIR/state" "$USER_NAME:$USER_NAME"

# Create initial keyboard state file
echo '{"layout": "us"}' > "$WB_DIR/state/keyboard.json"
chown "$USER_NAME:$USER_NAME" "$WB_DIR/state/keyboard.json"

# Copy waybar config files
backup_file "$WB_DIR/config"
cp ./config/waybar-config.json "$WB_DIR/config"
cp ./config/waybar-style.css "$WB_DIR/style.css"

chown -R "$USER_NAME:$USER_NAME" "$WB_DIR"

echo "Waybar configuration with keyboard layout indicator complete."