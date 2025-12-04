#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source ./helpers.sh
setup_user_vars

HW_PKGS=(intel-ucode intel-media-driver libva-utils tlp thermald powertop libinput
         pipewire pipewire-pulse wireplumber networkmanager bluez bluez-utils blueman)
echo "Installing hardware-related packages..."
for p in "${HW_PKGS[@]}"; do install_package "$p" || true; endone=false; done

echo "Enabling hardware services..."
for unit in NetworkManager.service bluetooth.service tlp.service thermald.service fstrim.timer; do
  enable_service "$unit" || true
done

echo "Configuring TLP for balanced power profile..."
if [[ -f /etc/tlp.conf ]]; then
  backup_file /etc/tlp.conf sudo || true
  sudo sed -i 's/^#\?TLP_DEFAULT_MODE=.*/TLP_DEFAULT_MODE=BAT/' /etc/tlp.conf || true
  sudo sed -i 's/^#\?CPU_ENERGY_PERF_POLICY_ON_BAT=.*/CPU_ENERGY_PERF_POLICY_ON_BAT=balance_power/' /etc/tlp.conf || true
  sudo sed -i 's/^#\?CPU_ENERGY_PERF_POLICY_ON_AC=.*/CPU_ENERGY_PERF_POLICY_ON_AC=balance_performance/' /etc/tlp.conf || true
  sudo sed -i 's/^#\?PLATFORM_PROFILE_ON_BAT=.*/PLATFORM_PROFILE_ON_BAT=balanced/' /etc/tlp.conf || true
  sudo sed -i 's/^#\?PLATFORM_PROFILE_ON_AC=.*/PLATFORM_PROFILE_ON_AC=balanced/' /etc/tlp.conf || true
  sudo sed -i 's/^#\?CPU_SCALING_GOVERNOR_ON_BAT=.*/CPU_SCALING_GOVERNOR_ON_BAT=powersave/' /etc/tlp.conf || true
  sudo sed -i 's/^#\?CPU_SCALING_GOVERNOR_ON_AC=.*/CPU_SCALING_GOVERNOR_ON_AC=powersave/' /etc/tlp.conf || true
  systemctl is-active --quiet tlp && sudo systemctl restart tlp || true
fi

echo "Checking kernel params for Intel power savings..."
if [[ -f /etc/default/grub ]]; then
  backup_file /etc/default/grub sudo || true
  add_param() {
    local key="GRUB_CMDLINE_LINUX" val="$1"
    if ! grep -q "$val" /etc/default/grub; then
      sudo sed -i "s|^$key=\"\\(.*\\)\"|$key=\"\\1 $val\"|" /etc/default/grub
      return 0
    fi
    return 1
  }
  add_param "i915.enable_psr=1" || true
  add_param "i915.enable_fbc=1" || true
  add_param "pcie_aspm.policy=powersave" || true
  command -v grub-mkconfig >/dev/null 2>&1 && sudo grub-mkconfig -o /boot/grub/grub.cfg || true
fi

echo "Setting up keyboard configuration..."
echo "Configuring caps2esc pipeline..."
install_file ./config/caps2esc.yaml /etc/interception/udevmon.d/caps2esc.yaml 644 sudo
enable_service udevmon.service || true
sudo systemctl start udevmon.service || true

echo "Hardware setup complete."