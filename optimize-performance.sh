#!/bin/bash
# Performance optimization script for ThinkPad X390

# Exit on any error
set -e

echo "Applying performance optimizations..."

# Enable TRIM for SSD
sudo systemctl enable fstrim.timer

# Install zRAM for better memory handling
sudo pacman -S --noconfirm zram-generator
echo '[zram0]
zram-size = ram / 2
compression-algorithm = zstd' | sudo tee /etc/systemd/zram-generator.conf

# Reduce swappiness for better responsiveness
echo 'vm.swappiness=10' | sudo tee /etc/sysctl.d/99-swappiness.conf

# Intel graphics acceleration
sudo pacman -S --noconfirm intel-media-driver libva-utils

# Set Firefox hardware acceleration
mkdir -p ~/.config/environment.d/
echo 'MOZ_X11_EGL=1
LIBVA_DRIVER_NAME=iHD' > ~/.config/environment.d/envvars.conf

# Optimize scheduler
echo 'kernel.sched_autogroup_enabled=0' | sudo tee -a /etc/sysctl.d/99-sysctl.conf

# Install preload for faster application loading
yay -S --noconfirm preload
sudo systemctl enable preload

# Set I/O scheduler for better responsiveness
echo 'ACTION=="add|change", KERNEL=="sd[a-z]|mmcblk[0-9]*|nvme[0-9]*", ATTR{queue/scheduler}="bfq"' | sudo tee /etc/udev/rules.d/60-ioscheduler.rules

# Intel P-State driver tweaks
echo 'options intel_pstate no_hwp=1' | sudo tee /etc/modprobe.d/intel_pstate.conf

# Consider linux-zen kernel (uncomment if desired)
# sudo pacman -S --noconfirm linux-zen linux-zen-headers

echo "Performance optimizations complete! Reboot your system to apply all changes."
echo "For best results, consider adding these parameters to your bootloader config:"
echo "intel_pstate=active pcie_aspm=off intel_idle.max_cstate=1"
