#!/bin/bash
# Network management script

OPTIONS="WiFi|Bluetooth|Connection Editor"

# Use wofi with explicit styling to match our theme
chosen=$(echo -e "$OPTIONS" | wofi --dmenu --insensitive --prompt="Network:" \
    --width=300 --height=200 --style="background-color: #FFFFFF; color: #111111;")

# Exit if cancelled
[ -z "$chosen" ] && exit 0

case "$chosen" in
    "WiFi")
        # Use alacritty with explicit settings
        alacritty --title "Network Manager" --class "floating" \
            --config-file="$HOME/.config/alacritty/alacritty.toml" -e nmtui
        ;;
    "Bluetooth")
        if command -v blueman-manager &>/dev/null; then
            blueman-manager
        else
            notify-send "Error" "Bluetooth manager not found" -u critical
            exit 1
        fi
        ;;
    "Connection Editor")
        nm-connection-editor
        ;;
esac