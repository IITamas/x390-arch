#!/usr/bin/env bash
# Sway desktop environment setup

# Load helper functions
source ./helpers.sh

# Check if running with sudo privileges
check_root

# Setup user variables
setup_user_vars

# Desktop packages
DESKTOP_PKGS=(
  # Sway and core components
  sway swaybg swayidle swaylock waybar wofi mako
  # Terminals
  alacritty foot
  # Desktop utilities
  grim slurp wl-clipboard cliphist brightnessctl playerctl
  # Monitor management
  wdisplays
  # Login manager
  greetd tuigreet
  # Fonts
  noto-fonts noto-fonts-emoji ttf-jetbrains-mono
  # Applications
  firefox
)

# Install desktop packages
echo "Installing desktop packages..."
for pkg in "${DESKTOP_PKGS[@]}"; do
  install_package "$pkg" || echo "Warning: Failed to install $pkg, continuing..."
done

# Install VSCodium
if ! pacman -Q codium &>/dev/null 2>&1; then
  echo "Installing VSCodium..."
  install_package codium || {
    echo "VSCodium not found in main repos, trying AUR..."
    sudo -u "$USER_NAME" yay -S --noconfirm vscodium-bin || echo "Failed to install VSCodium, continuing..."
  }
else
  echo "VSCodium is already installed."
fi

# Install glow for markdown preview
if ! pacman -Q glow &>/dev/null 2>&1; then
  echo "Installing glow markdown viewer..."
  sudo -u "$USER_NAME" yay -S --noconfirm glow || echo "Failed to install glow, continuing..."
fi

# Enable login manager
enable_service greetd

# Configure greetd
echo "Configuring greetd..."
sudo mkdir -p /etc/greetd
backup_file /etc/greetd/config.toml
sudo cp ./config/greetd.toml /etc/greetd/config.toml

# Environment for Wayland + VA-API
echo "Configuring environment variables..."
ensure_dir "$USER_HOME/.config/environment.d" "$USER_NAME:$USER_NAME"
cp ./config/wayland.conf "$USER_HOME/.config/environment.d/wayland.conf"
cp ./config/firefox.conf "$USER_HOME/.config/environment.d/firefox.conf"
chown -R "$USER_NAME:$USER_NAME" "$USER_HOME/.config/environment.d"

# VSCodium Wayland flags
ensure_dir "$USER_HOME/.config" "$USER_NAME:$USER_NAME"
cp ./config/codium-flags.conf "$USER_HOME/.config/codium-flags.conf"
chown "$USER_NAME:$USER_NAME" "$USER_HOME/.config/codium-flags.conf"

echo "Desktop environment base setup complete."