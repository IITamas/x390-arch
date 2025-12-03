#!/usr/bin/env bash
# ThinkPad X390 Setup - Main script with strict testing and fail-fast
# This script orchestrates all modules in the correct order

set -euo pipefail

echo "==============================================="
echo "ThinkPad X390 Setup - Arch Linux with Sway"
echo "==============================================="
echo "- Light theme"
echo "- US and Hungarian keyboard layouts (Alt+Shift, Win+Alt+k)"
echo "- Alacritty + Firefox + VSCodium"
echo "- Balanced power profile, caps2esc"
echo

# Preconditions
if [[ $EUID -eq 0 ]]; then
  echo "Error: Do not run as root. Use a regular user with sudo."
  exit 1
fi

if ! sudo -v &>/dev/null; then
  echo "Error: You need sudo privileges to run this script."
  exit 1
fi

if [[ ! -d "./config" ]]; then
  echo "Error: Config directory not found. Expected ./config"
  exit 1
fi

# Ensure scripts are executable before tests
chmod +x helpers.sh || true
chmod +x system_setup.sh || true
chmod +x hardware_setup.sh || true
chmod +x desktop_setup.sh || true
chmod +x sway_config.sh || true
chmod +x waybar_config.sh || true
chmod +x app_config.sh || true
chmod +x state.sh || true
chmod +x test.sh || true
find ./config -name "*.sh" -exec chmod +x {} \; || true

# Initialize state tracking if not present
if [[ ! -d ./.state ]]; then
  ./state.sh
fi

# Strict preflight tests: exit immediately on failure
echo "Running configuration tests..."
./test.sh all
echo "All tests passed."

# Confirm proceed
read -rp "Proceed with installation and configuration? [y/N]: " ans
if [[ ! "${ans:-}" =~ ^[Yy]$ ]]; then
  echo "Installation cancelled."
  exit 0
fi

# Run modules (fail-fast)
echo "Running system setup..."
./system_setup.sh

echo "Running hardware setup..."
./hardware_setup.sh

echo "Running desktop environment setup..."
./desktop_setup.sh

echo "Configuring Sway window manager..."
./sway_config.sh

echo "Configuring Waybar..."
./waybar_config.sh

echo "Configuring applications..."
./app_config.sh

echo "==============================================="
echo "✅ Setup complete!"
echo
echo "- Light theme across Sway/Waybar/Alacritty"
echo "- Keyboard: US/HU (Alt+Shift), toggle: Win+Alt+k"
echo "- Alacritty, Firefox (VA-API), VSCodium configured"
echo "- Balanced power profile, caps2esc enabled"
echo
echo "Idempotent: re-running applies only changed configs."
echo

read -rp "Reboot now to apply all changes? [y/N]: " reboot_ans
if [[ "${reboot_ans:-}" =~ ^[Yy]$ ]]; then
  sudo reboot
else
  echo "You can reboot manually when ready."
fi