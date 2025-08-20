#!/bin/bash
# Atari800 specific submenu placeholder
set -euo pipefail
DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
# shellcheck source=../lib/common.sh
. "$DIR/../lib/common.sh"

# Future variables for Atari emulator (placeholder)
ATARI_INSTALL_DIR="$HOME/atari800" # adjust when implemented

atari_menu() {
  local CHOICE
  while true; do
  CHOICE=$(whiptail --title "Atari800 Options" --backtitle "$BACKTITLE" \
      --ok-button "Select" --cancel-button "Back" \
      --menu "Atari800 configuration:" 12 60 3 \
      "1" "Configure Atari paths (todo)" \
      "2" "Return to main menu" 3>&1 1>&2 2>&3) || return 0
    case $CHOICE in
      1) msg "Configuration options coming soon." 8 50 ;;
      2) return 0 ;;
    esac
  done
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  atari_menu
fi
