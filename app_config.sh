#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source ./helpers.sh
setup_user_vars

# Alacritty
install_file ./config/alacritty.toml "$USER_HOME/.config/alacritty/alacritty.toml" 644 || true

# Swaylock
install_file ./config/swaylock.conf "$USER_HOME/.config/swaylock/config" 644 || true

# Mako
install_file ./config/mako.conf "$USER_HOME/.config/mako/config" 644 || true

# VSCodium settings
install_file ./config/codium-settings.json "$USER_HOME/.config/VSCodium/User/settings.json" 644 || true

# Firefox VA-API prefs (append once)
FF_DIR="$USER_HOME/.mozilla/firefox"
if [[ -d "$FF_DIR" ]]; then
  for profile in "$FF_DIR"/*.default-release; do
    [[ -d "$profile" ]] || continue
    PREFS="$profile/user.js"
    if [[ ! -f "$PREFS" ]] || ! grep -q "media.ffmpeg.vaapi.enabled" "$PREFS"; then
      cat ./config/firefox-user.js >> "$PREFS"
      sudo chown "$USER_NAME:$USER_NAME" "$PREFS" || true
      echo "Wrote Firefox VA-API prefs to $PREFS"
    else
      echo "Firefox VA-API prefs already present in $PREFS"
    fi
  done
else
  echo "Firefox profile directory not found. Settings will be applied when Firefox is first launched."
fi

sudo chown -R "$USER_NAME:$USER_NAME" "$USER_HOME/.config" || true
echo "Application configurations complete."