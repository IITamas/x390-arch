#!/bin/bash
# Toggle between US and Hungarian keyboard layouts

current_layout=$(swaymsg -t get_inputs | grep -A 15 "xkb_layout" | head -1 | awk -F'"' '{print $4}')

if [[ "$current_layout" == "us" ]] || [[ -z "$current_layout" ]]; then
    swaymsg input type:keyboard xkb_layout hu
    notify-send "Keyboard" "Switched to Hungarian layout" --icon=input-keyboard
else
    swaymsg input type:keyboard xkb_layout us
    notify-send "Keyboard" "Switched to US layout" --icon=input-keyboard
fi

# Update waybar keyboard state file for indicator
mkdir -p ~/.config/waybar/state
echo "{\"layout\": \"${current_layout}\"}" > ~/.config/waybar/state/keyboard.json