#!/bin/bash
# Common/shared functions and variables used by multiple emulator menus.

# Determine repository root (directory containing this file -> parent)
REPO_ROOT="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.." && pwd)"
VERSION_FILE="$REPO_ROOT/VERSION"
MENU_VERSION="$(grep -Eo '^[0-9]+\.[0-9]+\.[0-9]+' "$VERSION_FILE" 2>/dev/null | head -n1)"
[ -n "$MENU_VERSION" ] || MENU_VERSION="0.0.0"
BACKTITLE="8-bit PC Menu v$MENU_VERSION"

# Logging
LOG_DIR="$REPO_ROOT/logs"
LOG_FILE="$LOG_DIR/menu.log"
mkdir -p "$LOG_DIR" 2>/dev/null || true

log() { # level message...
  local level="$1"; shift
  printf '%s [%s] %s\n' "$(date -Iseconds)" "$level" "$*" >> "$LOG_FILE"
}
log_info(){ log INFO "$*"; }
log_warn(){ log WARN "$*"; }
log_error(){ log ERROR "$*"; }

# Utilities
require() {
  local bin
  for bin in "$@"; do
    command -v "$bin" >/dev/null 2>&1 || {
      echo "[ERROR] Required command '$bin' not found in PATH." >&2
      return 1
    }
  done
}

# Wrapper to show a message box (short helper to ensure consistent backtitle)
msg() { log_info "MSG: $1"; whiptail --backtitle "$BACKTITLE" --msgbox "$1" "${2:-8}" "${3:-50}"; }

confirm() { log_info "CONFIRM?: $1"; whiptail --backtitle "$BACKTITLE" --yesno "$1" "${2:-8}" "${3:-50}"; }

# Read current autostart emulator from ~/.bash_profile
get_autostart_emulator() {
  # Look inside RETROPC (new) or VICE (legacy) AUTOSTART block and extract executable name
  local line exe
  # Force fresh file read and more robust parsing
  line=$(grep -A 10 "# \(RETROPC\|VICE\) AUTOSTART START" "$HOME/.bash_profile" 2>/dev/null | grep -B 10 "# \(RETROPC\|VICE\) AUTOSTART END" | grep "/bin/" | tail -n1)
  exe=$(echo "$line" | sed 's/.*\///' | awk '{print $1}')
  [ -n "$exe" ] && echo "$exe" || echo ""
}

set_autostart_emulator() {
  # $1 = emulator executable path (absolute)
  local path="$1"
  [ -z "$path" ] && return 1
  touch "$HOME/.bash_profile"
  # Remove any existing RETROPC or legacy VICE blocks
  sed -i '/# \(RETROPC\|VICE\) AUTOSTART START/,/# \(RETROPC\|VICE\) AUTOSTART END/d' "$HOME/.bash_profile"
  {
    echo '# RETROPC AUTOSTART START'
    echo 'if [ -z "$SSH_CONNECTION" ]; then'
    echo "  $path"
    echo 'fi'
    echo '# RETROPC AUTOSTART END'
  } >> "$HOME/.bash_profile"
  log_info "Set autostart emulator to $path (RETROPC AUTOSTART block)"
}
