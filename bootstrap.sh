#!/bin/bash
# Simple bootstrap script for ThinkPad X390 running Arch Linux

# Exit on any error
set -e

echo "Installing base packages..."
sudo pacman -Syu --noconfirm base-devel git wget curl xorg-server xorg-xinit \
    i3-wm i3status dmenu firefox picom feh xclip maim \
    intel-ucode tlp tlp-rdw thermald powertop alacritty \
    network-manager-applet pulseaudio pavucontrol \
    xorg-setxkbmap

# Install yay AUR helper
if ! command -v yay &> /dev/null; then
    echo "Installing yay AUR helper..."
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd ..
    rm -rf yay
fi

echo "Installing AUR packages..."
yay -S --noconfirm xcape i3lock-color xkb-switch vscodium-bin acpi_call

# Create necessary directories
mkdir -p ~/.config/i3
mkdir -p ~/.config/i3status
mkdir -p ~/.local/bin
mkdir -p ~/.config/VSCodium/User

# Copy config files
echo "Copying configuration files..."
cp configs/i3config ~/.config/i3/config
cp configs/i3status.conf ~/.config/i3status/config
cp configs/lock.sh ~/.local/bin/
chmod +x ~/.local/bin/lock.sh
cp configs/xprofile ~/.xprofile
chmod +x ~/.xprofile
cp configs/xinitrc ~/.xinitrc
chmod +x ~/.xinitrc

# Setup VSCodium configuration
echo "Setting up VSCodium config..."
cp configs/vscodium-settings.json ~/.config/VSCodium/User/settings.json

# ThinkPad optimizations
echo "Setting up ThinkPad-specific optimizations..."
sudo systemctl enable --now tlp.service
sudo systemctl enable --now thermald.service

# Copy TLP config
sudo cp configs/tlp.conf /etc/tlp.conf

echo "Setting up Caps Lock to Ctrl/Esc..."
setxkbmap -option ctrl:nocaps
xcape -e 'Control_L=Escape'

echo "Setting up keyboard layouts (us, hu)..."
setxkbmap -layout us,hu -option grp:alt_shift_toggle

echo "Setup complete! Log out and log back in, or reboot to apply all changes."
echo "For additional performance optimizations, run ./optimize-performance.sh"
