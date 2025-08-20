#!/bin/bash
# VICE specific submenu logic
set -euo pipefail
DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
# shellcheck source=../lib/common.sh
. "$DIR/../lib/common.sh"

VICE_VERSION="3.9"
VICE_INSTALL_DIR=$HOME/vice-$VICE_VERSION
VICE_SHARE_DATA_DIR=$HOME/share/data
VICERC="$HOME/.config/vice/sdl-vicerc"

get_vicerc_section() {
  local emu="$1"
  case "$emu" in
    x64) echo "C64" ;;
    x64sc) echo "C64SC" ;;
    *) echo "" ;;
  esac
}

get_keyboard_layout() {
  local emu section keymap_file keymap_index keymap_pos_file
  emu=$(get_autostart_emulator)
  section=$(get_vicerc_section "$emu")
  [ -z "$section" ] && echo "Unknown" && return

  keymap_index=$(crudini --get "$VICERC" "$section" KeymapIndex 2>/dev/null || echo 0)
  keymap_file=$(crudini --get "$VICERC" "$section" KeymapUserSymFile 2>/dev/null || echo "")
  keymap_pos_file=$(crudini --get "$VICERC" "$section" KeymapUserPosFile 2>/dev/null || echo "")

  if [ "$keymap_index" = "3" ]; then
    case "$keymap_pos_file" in
      *sdl_c64p.vkm) echo "C64P - C64" ;;
      *) echo "Unknown" ;;
    esac; return
  fi
  if [ "$keymap_index" = "2" ]; then
    case "$keymap_file" in
      *sdl_sym_uk_pi_4-500_bmc64.vkm) echo "Pi400/Pi500 UK" ;;
      *sdl_sym_us_pi_4-500_bmc64.vkm) echo "Pi400/Pi500 US" ;;
      *sdl_sym_no_pi_4-500_bmc64.vkm) echo "Pi400/Pi500 NO" ;;
      *sdl_c64p.vkm) echo "C64P - C64" ;;
      *) echo "Unknown" ;;
    esac; return
  fi
  echo "Unknown"
}

set_keyboard_layout() {
  local emu section
  emu=$(get_autostart_emulator)
  section=$(get_vicerc_section "$emu")
  [ -z "$section" ] && return
  case "$1" in
    "Pi400/Pi500 UK") crudini --set "$VICERC" "$section" KeymapIndex 2; crudini --set "$VICERC" "$section" KeymapUserSymFile "$VICE_SHARE_DATA_DIR/C64/sdl_sym_uk_pi_4-500_bmc64.vkm"; sudo raspi-config nonint do_configure_keyboard gb ;;
    "Pi400/Pi500 US") crudini --set "$VICERC" "$section" KeymapIndex 2; crudini --set "$VICERC" "$section" KeymapUserSymFile "$VICE_SHARE_DATA_DIR/C64/sdl_sym_us_pi_4-500_bmc64.vkm"; sudo raspi-config nonint do_configure_keyboard us ;;
    "Pi400/Pi500 NO") crudini --set "$VICERC" "$section" KeymapIndex 2; crudini --set "$VICERC" "$section" KeymapUserSymFile "$VICE_SHARE_DATA_DIR/C64/sdl_sym_no_pi_4-500_bmc64.vkm"; sudo raspi-config nonint do_configure_keyboard no ;;
    "C64P - C64") crudini --set "$VICERC" "$section" KeymapIndex 3; crudini --set "$VICERC" "$section" KeymapUserPosFile "$VICE_SHARE_DATA_DIR/C64/sdl_c64p.vkm"; sudo raspi-config nonint do_configure_keyboard us ;;
  esac
  sed -i 's/^\([A-Za-z0-9_]\+\) *= */\1=/' "$VICERC"
}

# Joyport helpers migrated from original monolithic script
get_joyport_setup() {
  local emu section jd1 jd2 jp1
  emu=$(get_autostart_emulator)
  section=$(get_vicerc_section "$emu")
  [ -z "$section" ] && echo "Unknown" && return
  jd1=$(crudini --get "$VICERC" "$section" JoyDevice1 2>/dev/null || echo 0)
  jd2=$(crudini --get "$VICERC" "$section" JoyDevice2 2>/dev/null || echo 0)
  jp1=$(crudini --get "$VICERC" "$section" JoyPort1Device 2>/dev/null || echo 0)
  if [ "$jd1" -ge 4 ] && [ "$jd2" -ge 4 ]; then
    echo "J1-J2 USB"
  elif [ "$jp1" = "3" ] && [ "$jd2" -ge 4 ]; then
    echo "M1-J2 USB"
  elif [ "$jd1" = "2" ] && [ "$jd2" = "3" ]; then
    echo "J1-J2 GPIO"
  elif [ "$jp1" = "3" ] && [ "$jd2" = "3" ]; then
    echo "M1-J2 USB/GPIO"
  else
    echo "Unknown"
  fi
}

set_joyport_setup() {
  local emu section
  emu=$(get_autostart_emulator)
  section=$(get_vicerc_section "$emu")
  [ -z "$section" ] && return
  case "$1" in
    "J1-J2 USB")
      crudini --del "$VICERC" "$section" JoyPort1Device || true
      crudini --del "$VICERC" "$section" JoyPort2Device || true
      crudini --set "$VICERC" "$section" JoyDevice1 4
      crudini --set "$VICERC" "$section" JoyDevice2 4 ;;
    "M1-J2 USB")
      crudini --set "$VICERC" "$section" JoyPort1Device 3
      crudini --del "$VICERC" "$section" JoyPort2Device || true
      crudini --del "$VICERC" "$section" JoyDevice1 || true
      crudini --set "$VICERC" "$section" JoyDevice2 4 ;;
    "J1-J2 GPIO")
      crudini --del "$VICERC" "$section" JoyPort1Device || true
      crudini --del "$VICERC" "$section" JoyPort2Device || true
      crudini --set "$VICERC" "$section" JoyDevice1 2
      crudini --set "$VICERC" "$section" JoyDevice2 3 ;;
    "M1-J2 USB/GPIO")
      crudini --set "$VICERC" "$section" JoyPort1Device 3
      crudini --del "$VICERC" "$section" JoyPort2Device || true
      crudini --del "$VICERC" "$section" JoyDevice1 || true
      crudini --set "$VICERC" "$section" JoyDevice2 3 ;;
  esac
  sed -i 's/^\([A-Za-z0-9_]\+\) *= */\1=/' "$VICERC"
}

vice_menu() {
  local CURRENT_EMU KEYBOARD_LAYOUT JOYPORT_SETUP CHOICE
  while true; do
    CURRENT_EMU=$(get_autostart_emulator)
    KEYBOARD_LAYOUT=$(get_keyboard_layout)
    JOYPORT_SETUP=$(get_joyport_setup)
  CHOICE=$(whiptail --title "VICE Options" --backtitle "$BACKTITLE" \
      --ok-button "Select" --cancel-button "Back" \
      --menu "VICE configuration:" 20 80 10 \
      "1" "Select Pi keyboard layout (current: ${KEYBOARD_LAYOUT})" \
      "2" "Select joyport setup (current: ${JOYPORT_SETUP})" \
      "3" "Return to main menu" 3>&1 1>&2 2>&3) || return 0
    case $CHOICE in
      1)
        local KEYB
        KEYB=$(whiptail --title "Select Pi Keyboard Layout" --backtitle "$BACKTITLE" --default-item "${KEYBOARD_LAYOUT:-Pi400/Pi500 UK}" \
          --menu "Choose keyboard layout:" 15 70 4 \
          "Pi400/Pi500 UK" "UK keyboard layout for Pi400/Pi500" \
          "Pi400/Pi500 US" "US keyboard layout for Pi400/Pi500" \
          "Pi400/Pi500 NO" "Norwegian keyboard layout for Pi400/Pi500" \
          "C64P - C64" "C64 keyboard connected with C64P" 3>&1 1>&2 2>&3)
        [ -n "$KEYB" ] && { set_keyboard_layout "$KEYB"; msg "Keyboard layout set to $KEYB" 8 50; }
        ;;
      2)
        local JOY
        JOY=$(whiptail --title "Select Joyport Setup" --backtitle "$BACKTITLE" --default-item "${JOYPORT_SETUP:-J1-J2 USB}" \
          --menu "Choose joyport setup:" 15 70 4 \
          "J1-J2 USB" "Both joysticks on USB" \
          "M1-J2 USB" "Mouse (port 1) on USB, Joystick (port 2) on USB" \
          "J1-J2 GPIO" "Both joysticks on GPIO" \
          "M1-J2 USB/GPIO" "Mouse (port 1) on USB, Joystick (port 2) on GPIO" 3>&1 1>&2 2>&3)
        [ -n "$JOY" ] && { set_joyport_setup "$JOY"; msg "Joyports set to $JOY" 8 40; }
        ;;
      3) return 0 ;;
    esac
  done
}

# Allow running standalone
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  vice_menu
fi
