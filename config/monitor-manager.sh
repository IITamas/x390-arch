#!/bin/bash
# Monitor configuration script for Sway

CONFIG_OPTIONS="Auto-detect|Laptop only|External only|Duplicate|Extend right|Extend left|Custom (wdisplays)"

# Use wofi with explicit styling to match our theme
chosen=$(echo -e "$CONFIG_OPTIONS" | wofi --dmenu --insensitive --prompt="Monitor configuration:" \
    --width=400 --height=300 --style="background-color: #FFFFFF; color: #111111;")

# Exit if cancelled
[ -z "$chosen" ] && exit 0

# Get connected outputs
INTERNAL=$(swaymsg -t get_outputs | jq -r '.[] | select(.name | test("eDP")) | .name')
EXTERNAL=$(swaymsg -t get_outputs | jq -r '.[] | select(.name | test("HDMI|DP")) | .name')

# Fallback if no eDP found (some laptops use different naming)
if [ -z "$INTERNAL" ]; then
    INTERNAL=$(swaymsg -t get_outputs | jq -r '.[] | select(.name | test("LVDS|DSI")) | .name')
fi

case "$chosen" in
    "Auto-detect")
        if [ -n "$EXTERNAL" ]; then
            swaymsg output "$INTERNAL" enable
            swaymsg output "$EXTERNAL" enable
            swaymsg output "$EXTERNAL" position 1920 0
            notify-send "Monitor" "Auto-configured with external display"
        else
            swaymsg output "$INTERNAL" enable
            notify-send "Monitor" "Using laptop display only"
        fi
        ;;
    "Laptop only")
        swaymsg output "$INTERNAL" enable
        for output in $(swaymsg -t get_outputs | jq -r '.[] | select(.name != "'"$INTERNAL"'") | .name'); do
            swaymsg output "$output" disable
        done
        swaymsg output "$INTERNAL" enable
        notify-send "Monitor" "Using laptop display only"
        ;;
    "External only")
        if [ -n "$EXTERNAL" ]; then
            swaymsg output "$INTERNAL" disable
            swaymsg output "$EXTERNAL" enable
            notify-send "Monitor" "Using external display only"
        else
            notify-send "Error" "No external display detected!" -u critical
        fi
        ;;
    "Duplicate")
        if [ -n "$EXTERNAL" ]; then
            swaymsg output "$INTERNAL" enable
            swaymsg output "$EXTERNAL" enable
            swaymsg output "$EXTERNAL" position 0 0
            notify-send "Monitor" "Duplicating displays"
        else
            notify-send "Error" "No external display detected!" -u critical
        fi
        ;;
    "Extend right")
        if [ -n "$EXTERNAL" ]; then
            swaymsg output "$INTERNAL" enable
            swaymsg output "$EXTERNAL" enable
            swaymsg output "$EXTERNAL" position 1920 0
            notify-send "Monitor" "Extended display to the right"
        else
            notify-send "Error" "No external display detected!" -u critical
        fi
        ;;
    "Extend left")
        if [ -n "$EXTERNAL" ]; then
            swaymsg output "$INTERNAL" enable
            swaymsg output "$EXTERNAL" enable
            swaymsg output "$INTERNAL" position 1920 0
            swaymsg output "$EXTERNAL" position 0 0
            notify-send "Monitor" "Extended display to the left"
        else
            notify-send "Error" "No external display detected!" -u critical
        fi
        ;;
    "Custom (wdisplays)")
        wdisplays &
        ;;
esac

# Apply wallpaper to all displays - be explicit with color
swaymsg output "*" bg "#ECEFF1" solid_color