#!/usr/bin/env bash
set -euo pipefail

echo "==============================================="
echo "ThinkPad X390 Setup - Arch Linux with Sway"
echo "==============================================="
echo "- Light theme"
echo "- US and Hungarian keyboard layouts (Alt+Shift, Win+Alt+k)"
echo "- Alacritty + Firefox + VSCodium"
echo "- Balanced power profile, caps2esc"
echo

# Not root
if [[ $EUID -eq 0 ]]; then
  echo "Error: Do not run this script with sudo or as root."
  exit 1
fi

# sudo works
if ! command -v sudo >/dev/null 2>&1; then
  echo "Error: sudo not found. Install sudo and add your user to wheel."
  exit 1
fi
sudo -v >/dev/null || { echo "Error: sudo verification failed."; exit 1; }

# Executables
chmod +x helpers.sh system_setup.sh hardware_setup.sh desktop_setup.sh \
  sway_config.sh waybar_config.sh app_config.sh state.sh test.sh 2>/dev/null || true
find ./config -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true

# Optional state init
[[ -f ./state.sh ]] && [[ ! -d ./.state ]] && ./state.sh || true

# Tests first
echo "Running configuration tests..."
./test.sh all
echo "All tests passed."

read -rp "Proceed with installation and configuration? [y/N]: " ans
[[ "${ans:-}" =~ ^[Yy]$ ]] || { echo "Installation cancelled."; exit 0; }

echo "Running system setup..."
if ! ./system_setup.sh; then
  echo "Error: system_setup.sh failed. Aborting."
  exit 1
fi

echo "Running hardware setup..."
if ! ./hardware_setup.sh; then
  echo "Error: hardware_setup.sh failed. Aborting."
  exit 1
fi

echo "Running desktop environment setup..."
if ! ./desktop_setup.sh; then
  echo "Error: desktop_setup.sh failed. Aborting."
  exit 1
fi

echo "Configuring Sway window manager..."
if ! ./sway_config.sh; then
  echo "Error: sway_config.sh failed. Aborting."
  exit 1
fi

echo "Configuring Waybar..."
if ! ./waybar_config.sh; then
  echo "Error: waybar_config.sh failed. Aborting."
  exit 1
fi

echo "Configuring applications..."
if ! ./app_config.sh; then
  echo "Error: app_config.sh failed. Aborting."
  exit 1
fi

echo "==============================================="
echo "✅ Setup complete! Reboot recommended."