#!/usr/bin/env bash
# Core system setup - packages, services, and optimizations

# Load helper functions
source ./helpers.sh

# Check if running with sudo privileges
check_root

# Setup user variables
setup_user_vars

# Update system first
echo "Updating system..."
sudo pacman -Syu --noconfirm || { echo "System update failed"; exit 1; }

# Core packages
CORE_PKGS=(
  # Core utilities
  base-devel git man-db zip unzip jq
  # System management
  pacman-contrib reflector
)

# Install core packages
echo "Installing core packages..."
for pkg in "${CORE_PKGS[@]}"; do
  install_package "$pkg" || echo "Warning: Failed to install $pkg, continuing..."
done

# Setup reflector for better pacman mirrors
echo "Configuring reflector for optimal mirrors..."
if [[ -d /etc/xdg/reflector ]]; then
  backup_file /etc/xdg/reflector/reflector.conf
  sudo cp ./config/reflector.conf /etc/xdg/reflector/reflector.conf
  enable_service reflector.timer
fi

# Install yay AUR helper if not already installed
echo "Checking for yay AUR helper..."
if ! command -v yay &>/dev/null; then
  echo "Installing yay AUR helper..."
  WORKDIR="$(mktemp -d)"
  pushd "$WORKDIR" >/dev/null
  git clone https://aur.archlinux.org/yay.git
  cd yay
  makepkg -si --noconfirm
  popd >/dev/null
  rm -rf "$WORKDIR"
else
  echo "yay is already installed."
fi

# Set up regular package cleanup
echo "Setting up weekly pacman cache cleanup..."
sudo mkdir -p /etc/systemd/system/paccache.timer.d/
if [[ ! -f /etc/systemd/system/paccache.timer.d/override.conf ]]; then
  sudo bash -c 'cat > /etc/systemd/system/paccache.timer.d/override.conf' <<'EOF'
[Timer]
OnCalendar=weekly
Persistent=true
EOF
fi
enable_service paccache.timer

echo "Core system setup complete."