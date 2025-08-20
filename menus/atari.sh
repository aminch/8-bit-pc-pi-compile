#!/bin/bash
# Atari800 specific submenu placeholder
set -euo pipefail
DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
# shellcheck source=../lib/common.sh
. "$DIR/../lib/common.sh"

# Future variables for Atari emulator (placeholder)
ATARI_INSTALL_DIR="$HOME/atari800" # adjust when implemented
ATARI_CFG="$HOME/.atari800.cfg"

setup_gpio_joysticks() {
  local cfg="$ATARI_CFG"
  touch "$cfg"
  local -A pairs=(
    [SDL2_JOY_0_ENABLED]=1
    [SDL2_JOY_0_LEFT]=1073741919
    [SDL2_JOY_0_RIGHT]=1073741913
    [SDL2_JOY_0_UP]=1073741921
    [SDL2_JOY_0_DOWN]=1073741915
    [SDL2_JOY_0_TRIGGER]=1073741922
    [SDL2_JOY_1_ENABLED]=1
    [SDL2_JOY_1_LEFT]=1073741916
    [SDL2_JOY_1_RIGHT]=1073741918
    [SDL2_JOY_1_UP]=1073741920
    [SDL2_JOY_1_DOWN]=1073741914
    [SDL2_JOY_1_TRIGGER]=1073741917
  )
  if ! command -v crudini >/dev/null 2>&1; then
    msg "crudini not installed. Install with: sudo apt-get install -y crudini" 10 60
    return 1
  fi
  local k v
  for k in "${!pairs[@]}"; do
    v="${pairs[$k]}"
    crudini --set "$cfg" '' "$k" "$v" 2>/dev/null || {
      msg "Failed writing key $k" 8 50
      return 1
    }
  done
  # Remove accidental empty section header if crudini inserted one
  sed -i '/^\[\]$/d' "$cfg"
  msg "GPIO joystick mappings written." 8 45
}

atari_menu() {
  local CHOICE
  while true; do
  CHOICE=$(whiptail --title "Atari800 Options" --backtitle "$BACKTITLE" \
      --ok-button "Select" --cancel-button "Back" \
      --menu "Atari800 configuration:" 12 70 3 \
      "1" "Setup GPIO Joysticks" \
      "2" "Return to main menu" 3>&1 1>&2 2>&3) || return 0
    case $CHOICE in
      1) setup_gpio_joysticks ;;
      2) return 0 ;;
    esac
  done
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  atari_menu
fi
