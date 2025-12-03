#!/usr/bin/env bash
# Application configurations

# Load helper functions
source ./helpers.sh

# Setup user variables
setup_user_vars

# Alacritty config
echo "Configuring Alacritty..."
ALAC_DIR="$USER_HOME/.config/alacritty"
ensure_dir "$ALAC_DIR" "$USER_NAME:$USER_NAME"
backup_file "$ALAC_DIR/alacritty.toml"
cp ./config/alacritty.toml "$ALAC_DIR/alacritty.toml"

# Swaylock config
echo "Configuring swaylock..."
LOCK_DIR="$USER_HOME/.config/swaylock"
ensure_dir "$LOCK_DIR" "$USER_NAME:$USER_NAME"
cp ./config/swaylock.conf "$LOCK_DIR/config"

# Mako notifications config
echo "Configuring mako..."
MAKO_DIR="$USER_HOME/.config/mako"
ensure_dir "$MAKO_DIR" "$USER_NAME:$USER_NAME"
cp ./config/mako.conf "$MAKO_DIR/config"

# VSCodium settings
echo "Configuring VSCodium..."
VS_DIR="$USER_HOME/.config/VSCodium/User"
ensure_dir "$VS_DIR" "$USER_NAME:$USER_NAME"
backup_file "$VS_DIR/settings.json"
cp ./config/codium-settings.json "$VS_DIR/settings.json"

# Firefox VA-API settings
echo "Configuring Firefox for hardware video acceleration..."
FF_DIR="$USER_HOME/.mozilla/firefox"
if [[ -d "$FF_DIR" ]]; then
  for profile in "$FF_DIR"/*.default-release; do
    if [[ -d "$profile" ]]; then
      PREFS="$profile/user.js"
      
      # Only add settings if the file doesn't exist or doesn't already have the settings
      if [[ ! -f "$PREFS" ]] || ! grep -q "media.ffmpeg.vaapi.enabled" "$PREFS"; then
        echo "Writing Firefox hardware acceleration settings to $PREFS"
        cat ./config/firefox-user.js >> "$PREFS"
        chown "$USER_NAME:$USER_NAME" "$PREFS"
      else
        echo "Firefox hardware acceleration settings already configured."
      fi
    fi
  done
else
  echo "Firefox profile directory not found. Settings will be applied when Firefox is first launched."
fi

echo "Application configurations complete."