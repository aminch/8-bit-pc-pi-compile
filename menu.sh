#!/bin/bash
# New main retro menu entry point (VICE + Atari800 placeholder)
set -euo pipefail
BASE_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
. "$BASE_DIR/lib/common.sh"
VICE_MENU_SCRIPT="$BASE_DIR/menus/vice.sh"
ATARI_MENU_SCRIPT="$BASE_DIR/menus/atari.sh"

do_updates() {
  local UPDATE_CHOICE
  UPDATE_CHOICE=$(whiptail --title "Updates" --backtitle "$BACKTITLE" --menu "Choose update option:" 15 70 2 \
    "1" "Update scripts & Makefile (git pull)" \
    "2" "Update Pi OS" 3>&1 1>&2 2>&3) || return
  case $UPDATE_CHOICE in
    1)
      if confirm "Pull latest changes from git?" 10 60; then
        if git -C "$BASE_DIR" pull; then
          msg "Update complete. Restarting menu..." 8 40
          exec "$0"
        else
          msg "Git update failed. Check network or repo." 10 60
        fi
      fi ;;
    2)
      msg "Updating Pi OS. This may take a while..." 8 50
      sudo apt update && sudo apt upgrade -y
      msg "Pi OS update complete." 8 40 ;;
  esac
}

main_menu() {
  while true; do
    local current
    current=$(get_autostart_emulator)
    local CHOICE
    CHOICE=$(whiptail --title "8-bit PC Main Menu" --backtitle "$BACKTITLE" \
      --ok-button "Select" --cancel-button "Exit" \
      --menu "Choose an option:" 22 80 12 \
      "1" "Launch current emulator (${current:-none})" \
      "2" "Select autostart emulator (x64 / x64sc / atari800)" \
      "3" "VICE specific options" \
      "4" "Atari800 specific options" \
      "5" "Tools & Utilities" \
      "6" "Updates (scripts, Makefile, Pi OS)" \
      "7" "Reboot Raspberry Pi" \
      "8" "Shutdown Raspberry Pi" 3>&1 1>&2 2>&3) || break
    case $CHOICE in
      1)
        local current_emu
        current_emu=$(get_autostart_emulator)  # Get fresh value right before launch
        if [ -n "$current_emu" ]; then
          # Resolve possible locations for both VICE and Atari emulators
          # Stored autostart is executable name only, reconstruct candidate paths
          declare -a CANDIDATES
          CANDIDATES+=("$current_emu") # if already in PATH
          CANDIDATES+=("$HOME/vice-3.9/bin/$current_emu")
          CANDIDATES+=("$HOME/atari800/bin/$current_emu")
          # In case user previously stored full path (older block), include it directly if it exists
          if [[ "$current_emu" == */* && -x "$current_emu" ]]; then
            CANDIDATES=("$current_emu")
          fi
          found=""
          for c in "${CANDIDATES[@]}"; do
            if [ -x "$c" ]; then
              found="$c"; break
            fi
          done
          if [ -n "$found" ]; then
            log_info "Launching emulator: $found"
            "$found"
          else
            msg "Emulator '$current' not found in PATH or expected directories." 8 70
          fi
        else
          msg "No emulator set to autostart." 8 50
        fi ;;
      2)
    local SEL exec_path current_emu
        current_emu=$(get_autostart_emulator)
        SEL=$(whiptail --title "Select Autostart Emulator" --backtitle "$BACKTITLE" \
          --default-item "${current_emu:-x64sc}" \
          --menu "Choose emulator:" 15 60 3 \
          "x64" "VICE C64 (fast, Pi400)" \
          "x64sc" "VICE C64 (cycle exact, Pi500)" \
          "atari800" "Atari 8-bit" 3>&1 1>&2 2>&3) || true
        if [ -n "${SEL:-}" ]; then
          case "$SEL" in
            x64|x64sc) exec_path="$HOME/vice-3.9/bin/$SEL" ;;
            atari800) exec_path="$HOME/atari800/bin/$SEL" ;;
          esac
          if [ -x "$exec_path" ]; then
      set_autostart_emulator "$exec_path"
      msg "Autostart emulator set to $SEL" 8 40
      continue  # Force menu reload to show updated current emulator
          else
            msg "Executable for $SEL not found at $exec_path" 8 60
          fi
        fi ;;
      3) bash "$VICE_MENU_SCRIPT" ;;
      4) bash "$ATARI_MENU_SCRIPT" ;;
      5) tools_menu ;;
      6) do_updates ;;
      7) if confirm "Reboot Raspberry Pi now?" 8 40; then sudo reboot; fi ;;
      8) if confirm "Shutdown Raspberry Pi now?" 8 40; then sudo shutdown now; fi ;;
    esac
  done
}

set_video_mode() {
  local resolution="$1"
  local video_param="video=HDMI-A-1:$resolution"
  
  # Determine cmdline.txt path
  local cmdline_file
  if [ -d /boot/firmware ]; then
    cmdline_file="/boot/firmware/cmdline.txt"
  else
    cmdline_file="/boot/cmdline.txt"
  fi
  
  # Remove any existing video= parameter
  sudo sed -i 's/ video=HDMI-A-1:[^ ]*//' "$cmdline_file"
  
  # Add the new video parameter
  sudo sed -i "s/$/ $video_param/" "$cmdline_file"
  
  if confirm "Video mode set to $resolution. Reboot now to apply changes?" 10 60; then
    sudo reboot
  else
    msg "Video mode updated. Reboot required to take effect." 8 60
  fi
}

tools_menu() {
  while true; do
    local TCHOICE
    TCHOICE=$(whiptail --title "Tools & Utilities" --backtitle "$BACKTITLE" \
      --ok-button "Select" --cancel-button "Back" \
      --menu "Utilities:" 20 70 10 \
      "1" "Launch Midnight Commander" \
      "2" "Start Samba (Windows file sharing)" \
      "3" "Stop Samba (Windows file sharing)" \
      "4" "Launch raspi-config" \
      "5" "Set Pi to auto-login (console)" \
      "6" "Set video mode 1080p" \
      "7" "Set video mode 720p" \
      "8" "Return to main menu" 3>&1 1>&2 2>&3) || return 0
    case $TCHOICE in
      1) mc ;;
      2) sudo systemctl start smbd; msg "Samba started." 8 40 ;;
      3) sudo systemctl stop smbd; msg "Samba stopped." 8 40 ;;
      4) sudo raspi-config ;;
      5) make -C "$BASE_DIR" autologin_pi; msg "Auto-login setup complete." 8 50 ;;
      6) set_video_mode "1920x1080M@60" ;;
      7) set_video_mode "1280x720M@60" ;;
      8) return 0 ;;
    esac
  done
}

main_menu
