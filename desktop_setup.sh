#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source ./helpers.sh
setup_user_vars

DESKTOP_PKGS=(sway swaybg swayidle swaylock waybar wofi mako alacritty foot
              grim slurp wl-clipboard cliphist brightnessctl playerctl
              wdisplays greetd noto-fonts noto-fonts-emoji ttf-jetbrains-mono
              firefox)
echo "Installing desktop packages..."
for p in "${DESKTOP_PKGS[@]}"; do install_package "$p" || true; done

# VSCodium (repo or AUR)
if ! pacman -Q codium >/dev/null 2>&1; then
  install_package codium || { command -v yay >/dev/null 2>&1 && sudo -u "$USER_NAME" yay -S --noconfirm vscodium-bin || true; }
else
  echo "VSCodium is already installed."
fi

# Greetd + greeter selection (tuigreet preferred, fallback to agreety)
echo "Configuring login manager (greetd)..."
{
  pacman -Q greetd >/dev/null 2>&1 || install_package greetd || true

  HAVE_TUIGREET=false
  if command -v tuigreet >/dev/null 2>&1 || pacman -Q tuigreet >/dev/null 2>&1; then
    HAVE_TUIGREET=true
  else
    install_package tuigreet || true
    if ! command -v tuigreet >/dev/null 2>&1 && command -v yay >/dev/null 2>&1; then
      sudo -u "$USER_NAME" yay -S --noconfirm tuigreet greetd-tuigreet-bin greetd-tuigreet 2>/dev/null || true
      command -v tuigreet >/dev/null 2>&1 && HAVE_TUIGREET=true
    fi
  fi

  if systemctl list-unit-files greetd.service >/dev/null 2>&1; then
    backup_file /etc/greetd/config.toml sudo || true
    if $HAVE_TUIGREET; then
      install_file ./config/greetd.toml /etc/greetd/config.toml 644 sudo || true
    else
      cat <<'EOF' | write_file /etc/greetd/config.toml sudo 644
[terminal]
vt = 1

[default_session]
command = "agreety --cmd sway"
user = "greeter"
EOF
    fi
    enable_service greetd.service || true
  else
    echo "Warning: greetd.service not found; skipping greetd setup."
  fi
} || {
  echo "Warning: greetd configuration had a non-fatal error"; true
}

# Configuring environment variables...
echo "Configuring environment variables..."
{
  mkdir -p "$USER_HOME/.config/environment.d"
  install_file ./config/wayland.conf "$USER_HOME/.config/environment.d/wayland.conf" 644 || true
  install_file ./config/firefox.conf "$USER_HOME/.config/environment.d/firefox.conf" 644 || true
  install_file ./config/codium-flags.conf "$USER_HOME/.config/codium-flags.conf" 644 || true
  sudo chown -R "$USER_NAME:$USER_NAME" "$USER_HOME/.config" || true
} || {
  echo "Warning: environment variables section had a non-fatal error"; true
}
echo "Environment variables configured."

echo "Desktop environment setup complete."