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
  set_config_values "$ATARI_CFG" "GPIO joystick mappings written." pairs
}

reset_video_settings() {
  local -A video_settings=(
    [VIDEOMODE_WINDOW_WIDTH]=1280
    [VIDEOMODE_WINDOW_HEIGHT]=720
    [VIDEOMODE_WINDOWED]=1
    [VIDEOMODE_HORIZONTAL_AREA]=TV
    [VIDEOMODE_VERTICAL_AREA]=TV
    [VIDEOMODE_STRETCH]=FULL
    [VIDEOMODE_FIT]=BOTH
    [VIDEOMODE_IMAGE_ASPECT]=NONE
    [SCANLINES_PERCENTAGE]=20
    [INTERPOLATE_SCANLINES]=1
    [PILLARBOX]=1
  )
  set_config_values "$ATARI_CFG" "Video settings reset to defaults." video_settings
}

atari_menu() {
  local CHOICE
  while true; do
  CHOICE=$(whiptail --title "Atari800 Options" --backtitle "$BACKTITLE" \
      --ok-button "Select" --cancel-button "Back" \
      --menu "Atari800 configuration:" 15 70 4 \
      "1" "Setup GPIO Joysticks" \
      "2" "Reset video settings" \
      "3" "Return to main menu" 3>&1 1>&2 2>&3) || return 0
    case $CHOICE in
      1) setup_gpio_joysticks ;;
      2) reset_video_settings ;;
      3) return 0 ;;
    esac
  done
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  atari_menu
fi
