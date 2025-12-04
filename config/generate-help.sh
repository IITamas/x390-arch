#!/bin/bash
# Dynamic keybinding help generator for Sway

SWAY_CONFIG="${SWAY_CONFIG:-$HOME/.config/sway/config}"
HELP_DIR="$HOME/.config/sway/help"
HELP_FILE="$HELP_DIR/keybindings.md"

mkdir -p "$HELP_DIR"

# Initialize the help file with a header
cat > "$HELP_FILE" <<EOH
# Sway Keybindings

This help is automatically generated from your Sway config.

EOH

# Function to format keybind
format_key() {
    # Replace $mod with Win
    echo "$1" | sed 's/\$mod/Win/g'
}

# Extract variable definitions
declare -A variables
while read -r line; do
    var_name=$(echo "$line" | awk '{print $2}')
    var_value=$(echo "$line" | awk '{$1=$2=""; print $0}' | sed 's/^[ \t]*//')
    variables["$var_name"]="$var_value"
done < <(grep -E '^set \$' "$SWAY_CONFIG")

# Find all bindsym lines and categorize them
echo -e "## Keyboard Shortcuts\n" >> "$HELP_FILE"

while read -r line; do
    # Extract the keybind and command
    keybind=$(echo "$line" | awk '{print $2}')
    # Get everything after the keybind but before any comment
    cmd=$(echo "$line" | sed -E 's/^bindsym [^ ]+ //' | sed 's/ #.*$//')
    
    # Look for a comment after the command
    comment=$(echo "$line" | grep -oP '(?<=#).*$' | sed 's/^[ \t]*//')
    
    # If no comment, just use the command as is
    if [[ -z "$comment" ]]; then
        comment="$cmd"
    fi
    
    # Format the key for display
    formatted_key=$(format_key "$keybind")
    
    # Write to the help file
    echo "* \`$formatted_key\` - $comment" >> "$HELP_FILE"
    
done < <(grep -E '^bindsym' "$SWAY_CONFIG")

# Add touchpad gesture section if present
if grep -q "bindgesture" "$SWAY_CONFIG"; then
    echo -e "\n## Touchpad Gestures\n" >> "$HELP_FILE"
    
    while read -r line; do
        gesture=$(echo "$line" | awk '{print $2}')
        cmd=$(echo "$line" | sed -E 's/^bindgesture [^ ]+ //' | sed 's/ #.*$//')
        
        # Extract comment if available
        comment=$(echo "$line" | grep -oP '(?<=#).*$' | sed 's/^[ \t]*//')
        
        # If no comment, just use the command
        if [[ -z "$comment" ]]; then
            comment="$cmd"
        fi
        
        # Format the gesture description
        gesture_desc=$(echo "$gesture" | sed 's/:/ /g')
        
        # Write to the help file
        echo "* $gesture_desc - $comment" >> "$HELP_FILE"
        
    done < <(grep -E '^bindgesture' "$SWAY_CONFIG")
fi

# Add hardware keys section if present
if grep -q "XF86" "$SWAY_CONFIG"; then
    echo -e "\n## Hardware Keys\n" >> "$HELP_FILE"
    
    while read -r line; do
        key=$(echo "$line" | awk '{print $2}')
        cmd=$(echo "$line" | sed -E 's/^bindsym [^ ]+ //' | sed 's/ #.*$//')
        
        # Extract comment if available
        comment=$(echo "$line" | grep -oP '(?<=#).*$' | sed 's/^[ \t]*//')
        
        # If no comment, just use the command
        if [[ -z "$comment" ]]; then
            comment="$cmd"
        fi
        
        # Format the key name nicely
        key_name=$(echo "$key" | sed 's/XF86//')
        
        # Write to the help file
        echo "* $key_name - $comment" >> "$HELP_FILE"
        
    done < <(grep -E '^bindsym XF86' "$SWAY_CONFIG")
fi

echo "Keybinding help generated at $HELP_FILE"