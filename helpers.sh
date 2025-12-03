#!/usr/bin/env bash
# Enhanced helper functions with error handling and idempotency

# Source state management functions
source ./state.sh

# Global flag to track if any errors occurred
ERRORS_OCCURRED=false

confirm() {
  read -rp "$1 [y/N]: " ans
  [[ "${ans:-}" =~ ^[Yy]$ ]]
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Error: Missing command: $1"
    ERRORS_OCCURRED=true
    return 1
  }
}

setup_user_vars() {
  USER_NAME="${SUDO_USER:-$USER}"
  USER_HOME="$(getent passwd "$USER_NAME" | cut -d: -f6)"

  if [[ -z "$USER_HOME" ]]; then
    echo "Error: Could not determine home directory for user $USER_NAME"
    ERRORS_OCCURRED=true
    return 1
  fi

  echo "User: $USER_NAME  Home: $USER_HOME"
  return 0
}

check_root() {
  if [[ $EUID -ne 0 ]] && [[ -z "${SUDO_USER:-}" ]]; then
    echo "Error: This script needs to be run as a regular user with sudo privileges."
    ERRORS_OCCURRED=true
    return 1
  fi
  return 0
}

backup_file() {
  local file="$1"
  if [[ -f "$file" ]]; then
    local backup="${file}.bak.$(date +%s)"
    cp "$file" "$backup"
    echo "Created backup: $backup"
    return 0
  fi
  return 1
}

ensure_dir() {
  local dir="$1"
  local owner="${2:-}"
  
  # If directory doesn't exist, create it
  if [[ ! -d "$dir" ]]; then
    echo "Creating directory: $dir"
    mkdir -p "$dir"
    
    # Set owner if specified
    if [[ -n "$owner" ]]; then
      chown "$owner" "$dir"
    fi
    return 0
  else
    # Directory exists, check owner if specified
    if [[ -n "$owner" ]] && [[ "$(stat -c '%U:%G' "$dir")" != "$owner" ]]; then
      echo "Changing ownership of $dir to $owner"
      chown "$owner" "$dir"
      return 0
    fi
  fi
  
  # No changes needed
  return 1
}

install_package() {
  local pkg="$1"
  if ! pacman -Q "$pkg" &>/dev/null 2>&1; then
    if pacman -Si "$pkg" &>/dev/null 2>&1; then
      echo "Installing $pkg..."
      if ! sudo pacman -S --needed --noconfirm "$pkg"; then
        echo "Error: Failed to install $pkg"
        ERRORS_OCCURRED=true
        return 1
      fi
      return 0
    else
      echo "Package $pkg not found in repositories."
      ERRORS_OCCURRED=true
      return 1
    fi
  else
    echo "$pkg is already installed."
    return 0
  fi
}

enable_service() {
  local service="$1"
  if systemctl list-unit-files "$service" &>/dev/null; then
    if ! systemctl is-enabled --quiet "$service"; then
      echo "Enabling $service..."
      if ! sudo systemctl enable "$service"; then
        echo "Error: Failed to enable $service"
        ERRORS_OCCURRED=true
        return 1
      fi
    else
      echo "$service is already enabled."
    fi
  else
    echo "Service $service not found, skipping."
    return 1
  fi
  return 0
}

# Enhanced function to copy a config file with proper error handling and idempotency
copy_config() {
  local source="$1"
  local target="$2"
  local owner="${3:-}"
  
  # Check if source exists
  if [[ ! -f "$source" ]]; then
    echo "Error: Source file $source does not exist"
    ERRORS_OCCURRED=true
    return 1
  fi
  
  # Check if update is needed
  if ! needs_update "$source" "$target"; then
    echo "Config $target is already up to date, skipping"
    return 0
  fi
  
  # Create target directory if needed
  ensure_dir "$(dirname "$target")" "$owner"
  
  # Backup existing file
  backup_file "$target"
  
  # Copy the file
  echo "Updating $target..."
  if ! cp "$source" "$target"; then
    echo "Error: Failed to copy $source to $target"
    ERRORS_OCCURRED=true
    return 1
  fi
  
  # Set owner if specified
  if [[ -n "$owner" ]]; then
    if ! chown "$owner" "$target"; then
      echo "Error: Failed to change ownership of $target"
      ERRORS_OCCURRED=true
      return 1
    fi
  fi
  
  # Track the applied config
  track_applied "$source" "$target"
  
  return 0
}

# Function to handle errors and provide recovery options
handle_error() {
  local component="$1"
  local message="$2"
  
  echo "Error in $component: $message"
  
  # Check if we can continue or need to abort
  if confirm "Do you want to continue despite the error?"; then
    ERRORS_OCCURRED=true
    return 0
  else
    # Offer rollback options
    if confirm "Do you want to try to rollback $component?"; then
      if rollback "$component"; then
        echo "Rollback of $component was successful"
        return 0
      else
        echo "Rollback of $component failed"
        ERRORS_OCCURRED=true
        return 1
      fi
    else
      echo "Aborting script due to error in $component"
      exit 1
    fi
  fi
}

# Report any errors at the end of execution
report_errors() {
  if [[ "$ERRORS_OCCURRED" = true ]]; then
    echo "❌ One or more errors occurred during execution."
    echo "Check the output above for details."
    return 1
  else
    echo "✅ All operations completed successfully."
    return 0
  fi
}