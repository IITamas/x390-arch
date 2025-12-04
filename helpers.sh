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
  return 0
}

backup_file() {
  local file="$1"
  local use_sudo="${2:-}" 
  
  if [[ -f "$file" ]]; then
    local backup="${file}.bak.$(date +%s)"

    if [[ "$use_sudo" == "sudo" ]] then
        sudo cp "$file" "$backup"
    else
        cp "$file" "$backup"
    fi
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
  local unit="$1"
  # If no suffix provided, try appending .service
  if [[ "$unit" != *.service && "$unit" != *.timer && "$unit" != *.socket && "$unit" != *.target ]]; then
    if systemctl list-unit-files "${unit}.service" >/dev/null 2>&1; then
      unit="${unit}.service"
    fi
  fi

  if systemctl list-unit-files "$unit" >/dev/null 2>&1; then
    if ! systemctl is-enabled --quiet "$unit"; then
      sudo systemctl enable "$unit"
      echo "Enabled: $unit"
    else
      echo "Already enabled: $unit"
    fi
  else
    echo "Unit not found: $unit (skipping)"
    return 1
  fi
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

# Install/copy a file if content differs; optional sudo, sets mode
# Usage: install_file SRC DEST [MODE] [sudo]
install_file() {
  local src="$1" dest="$2" mode="${3:-644}" use_sudo="${4:-}"
  [[ -f "$src" ]] || { echo "Error: missing $src"; return 1; }

  # If target exists and is identical, skip
  if [[ -f "$dest" ]] && diff -q "$src" "$dest" >/dev/null 2>&1; then
    echo "Up-to-date: $dest"
    return 0
  fi

  local dir; dir="$(dirname "$dest")"
  if [[ "$use_sudo" == "sudo" ]]; then
    sudo mkdir -p "$dir"
    backup_file "$dest" sudo || true
    sudo install -m "$mode" "$src" "$dest"
  else#!/usr/bin/env bash
set -euo pipefail

# Optional state tracking
if [[ -f ./state.sh ]]; then
  # shellcheck disable=SC1091
  source ./state.sh
fi

confirm() {
  read -rp "$1 [y/N]: " ans
  [[ "${ans:-}" =~ ^[Yy]$ ]]
}

setup_user_vars() {
  USER_NAME="${SUDO_USER:-$USER}"
  USER_HOME="$(getent passwd "$USER_NAME" | cut -d: -f6)"
  if [[ -z "${USER_HOME:-}" ]]; then
    echo "Error: Could not determine home for $USER_NAME"
    exit 1
  fi
}

# Backup a file with optional sudo
# Usage: backup_file /etc/file sudo
backup_file() {
  local file="$1"
  local use_sudo="${2:-}" # "sudo" or empty
  local ts; ts="$(date +%s)"
  local dest="${file}.bak.${ts}"

  if [[ "$use_sudo" == "sudo" ]]; then
    if sudo test -f "$file"; then
      sudo install -m 600 "$file" "$dest" 2>/dev/null || sudo cp "$file" "$dest"
      echo "Created backup: $dest"
      return 0
    fi
  else
    if [[ -f "$file" ]]; then
      install -m 600 "$file" "$dest" 2>/dev/null || cp "$file" "$dest"
      echo "Created backup: $dest"
      return 0
    fi
  fi
  return 1
}

# Install a file if content differs; optional sudo, sets mode
# Usage: install_file SRC DEST [MODE] [sudo]
install_file() {
  local src="$1" dest="$2" mode="${3:-644}" use_sudo="${4:-}"
  [[ -f "$src" ]] || { echo "Error: missing $src"; return 1; }

  if [[ -f "$dest" ]] && diff -q "$src" "$dest" >/dev/null 2>&1; then
    echo "Up-to-date: $dest"
    return 0
  fi

  local dir; dir="$(dirname "$dest")"
  if [[ "$use_sudo" == "sudo" ]]; then
    sudo mkdir -p "$dir"
    backup_file "$dest" sudo || true
    sudo install -m "$mode" "$src" "$dest"
  else
    mkdir -p "$dir"
    backup_file "$dest" || true
    install -m "$mode" "$src" "$dest"
  fi
  echo "Installed: $dest"
  return 0
}

# Write stdin to destination atomically; optional sudo
# Usage: echo "..." | write_file /etc/file sudo 644
write_file() {
  local dest="$1" use_sudo="${2:-}" mode="${3:-644}"
  local dir; dir="$(dirname "$dest")"
  local tmp; tmp="$(mktemp)"
  cat >"$tmp"
  if [[ "$use_sudo" == "sudo" ]]; then
    sudo mkdir -p "$dir"
    backup_file "$dest" sudo || true
    sudo install -m "$mode" "$tmp" "$dest"
  else
    mkdir -p "$dir"
    backup_file "$dest" || true
    install -m "$mode" "$tmp" "$dest"
  fi
  rm -f "$tmp"
  echo "Wrote: $dest"
}

# Enable a service; tolerate missing units; accept raw name or unit with suffix
enable_service() {
  local unit="$1"
  if [[ "$unit" != *.service && "$unit" != *.timer && "$unit" != *.socket && "$unit" != *.target ]]; then
    if systemctl list-unit-files "${unit}.service" >/dev/null 2>&1; then
      unit="${unit}.service"
    fi
  fi

  if systemctl list-unit-files "$unit" >/dev/null 2>&1; then
    if ! systemctl is-enabled --quiet "$unit"; then
      sudo systemctl enable "$unit"
      echo "Already enabled: $unit" | sed 's/Already/Enabled/'
    else
      echo "Already enabled: $unit"
    fi
  else
    echo "Unit not found: $unit (skipping)"
    return 1
  fi
}

# Install a package if available
install_package() {
  local pkg="$1"
  if pacman -Q "$pkg" >/dev/null 2>&1; then
    echo "$pkg is already installed."
    return 0
  fi
  if pacman -Si "$pkg" >/dev/null 2>&1; then
    sudo pacman -S --needed --noconfirm "$pkg"
    echo "$pkg installed."
    return 0
  else
    echo "Package $pkg not found in repositories."
    return 1
  fi
}
    mkdir -p "$dir"
    backup_file "$dest" || true
    install -m "$mode" "$src" "$dest"
  fi
  echo "Installed: $dest"
  return 0
}

# Write stdin to a destination file atomically; optional sudo
# Usage: echo "text" | write_file /etc/foo.conf sudo 644
write_file() {
  local dest="$1" use_sudo="${2:-}" mode="${3:-644}"
  local dir; dir="$(dirname "$dest")"
  local tmp; tmp="$(mktemp)"
  cat >"$tmp"
  if [[ "$use_sudo" == "sudo" ]]; then
    sudo mkdir -p "$dir"
    backup_file "$dest" sudo || true
    sudo install -m "$mode" "$tmp" "$dest"
  else
    mkdir -p "$dir"
    backup_file "$dest" || true
    install -m "$mode" "$tmp" "$dest"
  fi
  rm -f "$tmp"
  echo "Wrote: $dest"
}