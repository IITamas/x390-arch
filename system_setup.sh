#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source ./helpers.sh
setup_user_vars

echo "Updating system..."
sudo pacman -Syu --noconfirm

CORE_PKGS=(base-devel git jq man-db zip unzip pacman-contrib reflector)
echo "Installing core packages..."
for p in "${CORE_PKGS[@]}"; do install_package "$p" || true; done

echo "Configuring reflector for optimal mirrors..."
if [[ -d /etc/xdg/reflector ]]; then
  install_file ./config/reflector.conf /etc/xdg/reflector/reflector.conf 644 sudo
  enable_service reflector.timer || true
fi

echo "Checking for yay AUR helper..."
if ! command -v yay >/dev/null 2>&1; then
  echo "Installing yay AUR helper..."
  work="$(mktemp -d)"; pushd "$work" >/dev/null
  git clone https://aur.archlinux.org/yay.git
  cd yay
  makepkg -si --noconfirm
  popd >/dev/null
  rm -rf "$work"
else
  echo "yay is already installed."
fi

echo "Setting up weekly pacman cache cleanup..."
sudo mkdir -p /etc/systemd/system/paccache.timer.d
if [[ -f /etc/systemd/system/paccache.timer.d/override.conf ]]; then
  backup_file /etc/systemd/system/paccache.timer.d/override.conf sudo || true
fi
cat <<'EOF' | write_file /etc/systemd/system/paccache.timer.d/override.conf sudo 644
[Timer]
OnCalendar=weekly
Persistent=true
EOF
enable_service paccache.timer || true

echo "Core system setup complete."