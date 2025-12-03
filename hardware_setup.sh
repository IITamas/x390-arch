#!/usr/bin/env bash
# ThinkPad X390 hardware optimization

# Load helper functions
source ./helpers.sh

# Check if running with sudo privileges
check_root

# Setup user variables
setup_user_vars

# Hardware-specific packages
HW_PKGS=(
  # Intel-specific
  intel-ucode intel-media-driver libva-utils
  # Power management
  tlp thermald powertop
  # Input devices
  libinput
  # Audio
  pipewire pipewire-pulse wireplumber
  # Network/Bluetooth
  networkmanager bluez bluez-utils blueman
)

# Install hardware packages
echo "Installing hardware-related packages..."
for pkg in "${HW_PKGS[@]}"; do
  install_package "$pkg" || echo "Warning: Failed to install $pkg, continuing..."
done

# Enable hardware services
echo "Enabling hardware services..."
for service in NetworkManager bluetooth tlp thermald fstrim.timer; do
  enable_service "$service" || echo "Warning: Could not enable $service"
done

# TLP tuning for balanced power profile
echo "Configuring TLP for balanced power profile..."
if [[ -f /etc/tlp.conf ]]; then
  backup_file /etc/tlp.conf

  # Update TLP settings for balanced profile
  sudo sed -i 's/^#\?TLP_DEFAULT_MODE=.*/TLP_DEFAULT_MODE=BAT/' /etc/tlp.conf
  sudo sed -i 's/^#\?CPU_ENERGY_PERF_POLICY_ON_BAT=.*/CPU_ENERGY_PERF_POLICY_ON_BAT=balance_power/' /etc/tlp.conf
  sudo sed -i 's/^#\?CPU_ENERGY_PERF_POLICY_ON_AC=.*/CPU_ENERGY_PERF_POLICY_ON_AC=balance_performance/' /etc/tlp.conf
  sudo sed -i 's/^#\?PLATFORM_PROFILE_ON_BAT=.*/PLATFORM_PROFILE_ON_BAT=balanced/' /etc/tlp.conf
  sudo sed -i 's/^#\?PLATFORM_PROFILE_ON_AC=.*/PLATFORM_PROFILE_ON_AC=balanced/' /etc/tlp.conf
  sudo sed -i 's/^#\?CPU_SCALING_GOVERNOR_ON_BAT=.*/CPU_SCALING_GOVERNOR_ON_BAT=powersave/' /etc/tlp.conf
  sudo sed -i 's/^#\?CPU_SCALING_GOVERNOR_ON_AC=.*/CPU_SCALING_GOVERNOR_ON_AC=powersave/' /etc/tlp.conf
  
  # Restart TLP if running
  if systemctl is-active --quiet tlp; then
    sudo systemctl restart tlp
  fi
fi

# GRUB kernel parameters for Intel power saving
if [[ -f /etc/default/grub ]]; then
  echo "Checking kernel params for Intel power savings..."
  backup_file /etc/default/grub
  
  changes=0
  # Function to safely append kernel parameters
  append_param() {
    local file="$1" key="$2" val="$3"
    if grep -q "^$key=" "$file"; then
      if ! grep -q "$val" "$file"; then
        sudo sed -i "s|^$key=\"\\(.*\\)\"|$key=\"\\1 $val\"|" "$file"
        return 1
      fi
    fi
    return 0
  }
  
  append_param /etc/default/grub GRUB_CMDLINE_LINUX "i915.enable_psr=1" || ((changes++))
  append_param /etc/default/grub GRUB_CMDLINE_LINUX "i915.enable_fbc=1" || ((changes++))
  append_param /etc/default/grub GRUB_CMDLINE_LINUX "pcie_aspm.policy=powersave" || ((changes++))
  
  if [[ $changes -gt 0 ]] && command -v grub-mkconfig >/dev/null 2>&1; then
    echo "Updating GRUB configuration..."
    sudo grub-mkconfig -o /boot/grub/grub.cfg
  fi
fi

# Configure keyboard layout and caps2esc
echo "Setting up keyboard configuration..."

# Install interception-tools and caps2esc if not already installed
if ! pacman -Q interception-tools &>/dev/null 2>&1 || ! pacman -Q interception-caps2esc &>/dev/null 2>&1; then
  echo "Installing interception-tools and caps2esc from AUR..."
  sudo -u "$USER_NAME" yay -S --noconfirm interception-tools interception-caps2esc || {
    echo "Failed to install interception tools. Exiting."
    exit 1
  }
fi

echo "Configuring caps2esc pipeline..."
sudo mkdir -p /etc/interception/udevmon.d
sudo cp ./config/caps2esc.yaml /etc/interception/udevmon.d/caps2esc.yaml

enable_service udevmon.service

echo "Hardware setup complete."