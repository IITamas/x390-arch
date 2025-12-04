#!/bin/bash
# Show keybinding help in a floating window

# First, regenerate the help file from current config
~/.config/sway/scripts/generate-help.sh

# Then display it - try glow first, fall back to less
if command -v glow &>/dev/null; then
    alacritty --class "floating" -e bash -c "glow -p ~/.config/sway/help/keybindings.md; read -p 'Press Enter to close '"
else
    alacritty --class "floating" -e bash -c "less ~/.config/sway/help/keybindings.md; read -p 'Press Enter to close '"
fi