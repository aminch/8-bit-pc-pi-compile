#!/bin/bash
# New main retro menu entry point (VICE + Atari800 placeholder)
set -euo pipefail
BASE_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
. "$BASE_DIR/lib/common.sh"
VICE_MENU_SCRIPT="$BASE_DIR/menus/vice.sh"
ATARI_MENU_SCRIPT="$BASE_DIR/menus/atari.sh"

do_updates() {
  local UPDATE_CHOICE
  UPDATE_CHOICE=$(whiptail --title "Updates" --backtitle "$BACKTITLE" \
    --ok-button "Select" --cancel-button "Back" \
    --menu "Choose update option:" 15 70 3 \
    "1" "Update scripts & Makefile (git pull)" \
    "2" "Update Pi OS" \
    "3" "Return to main menu" 3>&1 1>&2 2>&3) || return 0
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
    3)
      return 0 ;;
  esac

}

main_menu() {
  while true; do
    local current
    current=$(get_autostart_emulator)
    local CHOICE
    CHOICE=$(whiptail --title "8-bit PC Main Menu (Current: ${current:-none})" --backtitle "$BACKTITLE" \
      --ok-button "Select" --cancel-button "Exit" \
      --menu "Choose an option:" 22 80 12 \
      "1" "Launch current emulator (${current:-none})" \
      "2" "Select autostart emulator (x64 / x64sc / atari800)" \
      "3" "${current:-none} emulator options" \
      "4" "Tools & Utilities" \
      "5" "Updates (scripts, Makefile, Pi OS)" \
      "6" "Reboot Raspberry Pi" \
      "7" "Shutdown Raspberry Pi" 3>&1 1>&2 2>&3) || break
    case $CHOICE in
      1)
        local current_emu
        current_emu=$(get_autostart_emulator)  # Get fresh value right before launch
        if [ -n "$current_emu" ]; then
          case "$current_emu" in
            x64|x64sc)
              log_info "Launching VICE emulator: $current_emu"
              "$HOME/vice-3.9/bin/$current_emu" ;;
            atari800)
              log_info "Launching Atari emulator: $current_emu"
              "$HOME/atari800/bin/$current_emu" ;;
            *)
              msg "Unknown emulator: $current_emu" 8 50 ;;
          esac
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
      3)
        case "$current" in
          x64|x64sc)
            bash "$VICE_MENU_SCRIPT"
            ;;
          atari800)
            bash "$ATARI_MENU_SCRIPT"
            ;;
          *)
            msg "No options available for emulator: $current" 8 50
            ;;
        esac
        ;;
      4) tools_menu ;;
      5) do_updates ;;
      6) if confirm "Reboot Raspberry Pi now?" 8 40; then sudo reboot; fi ;;
      7) if confirm "Shutdown Raspberry Pi now?" 8 40; then sudo shutdown now; fi ;;
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
    local TCHOICE usb_mounted usb_menu_label
    usb_mounted=$(mount | grep -q 'on /media/usb ' && echo "yes" || echo "no")
    if [ "$usb_mounted" = "yes" ]; then
      usb_menu_label="Unmount USB Drive"
    else
      usb_menu_label="Mount USB Drive"
    fi

    TCHOICE=$(whiptail --title "Tools & Utilities" --backtitle "$BACKTITLE" \
      --ok-button "Select" --cancel-button "Back" \
      --menu "Utilities:" 20 70 10 \
      "1" "Launch Midnight Commander" \
      "2" "$usb_menu_label" \
      "3" "Start Samba (Windows file sharing)" \
      "4" "Stop Samba (Windows file sharing)" \
      "5" "Launch raspi-config" \
      "6" "Set Pi to auto-login (console)" \
      "7" "Set video mode 1080p" \
      "8" "Set video mode 720p" \
      "9" "Return to main menu" 3>&1 1>&2 2>&3) || return 0

    case $TCHOICE in
      1) mc ;;
      2)
        if [ "$usb_mounted" = "yes" ]; then
          sudo umount /media/usb && msg "USB drive unmounted." 8 40 || msg "Failed to unmount USB drive." 8 40
        else
          mount_usb_menu
        fi
        ;;
      3) sudo systemctl start smbd; msg "Samba started." 8 40 ;;
      4) sudo systemctl stop smbd; msg "Samba stopped." 8 40 ;;
      5) sudo raspi-config ;;
      6) make -C "$BASE_DIR" autologin_pi; msg "Auto-login setup complete." 8 50 ;;
      7) set_video_mode "1920x1080M@60" ;;
      8) set_video_mode "1280x720M@60" ;;
      9) return 0 ;;
    esac
  done
}

mount_usb_menu() {
  local usb_devices device_list device mount_point MOUNT_CHOICE
  log_info "mount_usb_menu: scanning for unmounted USB partitions"
  usb_partitions=$(lsblk -o NAME,TRAN,TYPE,MOUNTPOINT -nr | awk '$2=="usb" && $3=="part" && $4=="" {print "/dev/"$1}')
  log_info "mount_usb_menu: found partitions: $usb_partitions"
  if [ -n "$usb_partitions" ]; then
    device_list=()
    for part in $usb_partitions; do
      device_list+=("$part" "USB partition")
    done
  else
    log_info "mount_usb_menu: no unmounted partitions, checking for unmounted USB disks"
    usb_disks=$(lsblk -o NAME,TRAN,TYPE,MOUNTPOINT -nr | awk '$2=="usb" && $3=="disk" && $4=="" {print "/dev/"$1}')
    log_info "mount_usb_menu: found disks: $usb_disks"
    if [ -z "$usb_disks" ]; then
      log_warn "mount_usb_menu: No unmounted USB partitions or disks detected"
      msg "No unmounted USB partitions or disks detected." 8 50
      return 0
    fi
    device_list=()
    for disk in $usb_disks; do
      device_list+=("$disk" "USB disk (no partition table)")
    done
  fi

  MOUNT_CHOICE=$(whiptail --title "Mount USB Device" --backtitle "$BACKTITLE" \
    --ok-button "Mount" --cancel-button "Back" \
    --menu "Select a USB device to mount:" 15 60 6 \
    "${device_list[@]}" 3>&1 1>&2 2>&3) || { log_info "mount_usb_menu: User cancelled USB mount menu"; return 0; }

  if [ -n "$MOUNT_CHOICE" ]; then
    mount_point="/media/usb"
    log_info "mount_usb_menu: Attempting to mount $MOUNT_CHOICE at $mount_point"
    sudo mkdir -p "$mount_point"
    if sudo mount "$MOUNT_CHOICE" "$mount_point"; then
      log_info "mount_usb_menu: Successfully mounted $MOUNT_CHOICE at $mount_point"
      msg "Mounted $MOUNT_CHOICE at $mount_point" 8 50
    else
      log_error "mount_usb_menu: Failed to mount $MOUNT_CHOICE at $mount_point"
      log_error "mount_usb_menu: mount output: $(sudo mount "$MOUNT_CHOICE" "$mount_point" 2>&1)"
      msg "Failed to mount $MOUNT_CHOICE" 8 50
    fi
  fi
}

# Start the main menu when the script is run
main_menu
