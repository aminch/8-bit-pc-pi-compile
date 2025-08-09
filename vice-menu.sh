#!/bin/bash

# Vice install dir
VICE_VERSION="3.9"
VICE_INSTALL_DIR=$HOME/vice-$VICE_VERSION
VICE_SHARE_DATA_DIR=$HOME/vice-share/data

# Path to this scripts directory
DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"

# Config file for VICE
VICERC="$HOME/.config/vice/sdl-vicerc"

get_current_bash_profile_emulator() {
    grep "/vice-${VICE_VERSION}/bin/x" "$HOME/.bash_profile" 2>/dev/null | grep -E 'x64sc|x64' | awk -F'/' '{print $NF}'
}

#echo "[DEBUG] Current emulator in .bash_profile: $(get_current_bash_profile_emulator)"

set_bash_profile_emulator() {
    local emulator="$1"
    # Create .bash_profile if it doesn't exist
    [ -f "$HOME/.bash_profile" ] || touch "$HOME/.bash_profile"
    # Remove old block
    sed -i '/# VICE AUTOSTART START/,/# VICE AUTOSTART END/d' "$HOME/.bash_profile"
    # Add new block
    {
        echo "# VICE AUTOSTART START"
        echo 'if [ -z "$SSH_CONNECTION" ]; then'
        echo "  $VICE_INSTALL_DIR/bin/$emulator"
        echo "fi"
        echo "# VICE AUTOSTART END"
    } >> "$HOME/.bash_profile"
}

get_vicerc_section() {
    local emu="$1"
    case "$emu" in
        x64)      echo "C64" ;;
        x64sc)    echo "C64SC" ;;
        x128)     echo "C128" ;;
        xvic)     echo "VIC20" ;;
        xpet)     echo "PET" ;;
        xplus4)   echo "PLUS4" ;;
        xcbm2)    echo "CBM2" ;;
        xcbm5x0)  echo "CBM5x0" ;;
        xscpu64)  echo "SCPU64" ;;
        x64dtv)   echo "C64DTV" ;;
        vsid)     echo "VSID" ;;
        *)        echo "" ;;
    esac
}

get_keyboard_layout() {
    local emu section keymap_file keymap_index keymap_pos_file
    emu=$(get_current_bash_profile_emulator)
    section=$(get_vicerc_section "$emu")
    [ -z "$section" ] && echo "Unknown" && return

    keymap_index=$(crudini --get "$VICERC" "$section" KeymapIndex 2>/dev/null || echo 0)
    keymap_file=$(crudini --get "$VICERC" "$section" KeymapUserSymFile 2>/dev/null || echo "")
    keymap_pos_file=$(crudini --get "$VICERC" "$section" KeymapUserPosFile 2>/dev/null || echo "")

    # Check if it's using positional keymap (index 1) with sdl_c64p.vkm for C64P
    if [ "$keymap_index" = "1" ] && [ "$keymap_pos_file" = "sdl_c64p.vkm" ]; then
        echo "C64P - Original C64"
        return
    fi

    # Check symbolic keymap files
    case "$keymap_file" in
        *sdl_sym_uk_pi_4-500_bmc64.vkm) echo "Pi400/Pi500 UK" ;;
        *sdl_sym_us_pi_4-500_bmc64.vkm) echo "Pi400/Pi500 US" ;;
        *sdl_sym_no_pi_4-500_bmc64.vkm) echo "Pi400/Pi500 NO" ;;
        *) echo "Unknown" ;;
    esac
}

set_keyboard_layout() {
    local emu section
    emu=$(get_current_bash_profile_emulator)
    section=$(get_vicerc_section "$emu")
    [ -z "$section" ] && return

    case "$1" in
        "Pi400/Pi500 UK")
            crudini --set "$VICERC" "$section" KeymapIndex 2
            crudini --set "$VICERC" "$section" KeymapUserSymFile "$VICE_SHARE_DATA_DIR/C64/sdl_sym_uk_pi_4-500_bmc64.vkm"
            # Set Raspberry Pi OS keyboard to UK
            sudo raspi-config nonint do_configure_keyboard gb
            ;;
        "Pi400/Pi500 US")
            crudini --set "$VICERC" "$section" KeymapIndex 2
            crudini --set "$VICERC" "$section" KeymapUserSymFile "$VICE_SHARE_DATA_DIR/C64/sdl_sym_us_pi_4-500_bmc64.vkm"
            # Set Raspberry Pi OS keyboard to US
            sudo raspi-config nonint do_configure_keyboard us
            ;;
        "Pi400/Pi500 NO")
            crudini --set "$VICERC" "$section" KeymapIndex 2
            crudini --set "$VICERC" "$section" KeymapUserSymFile "$VICE_SHARE_DATA_DIR/C64/sdl_sym_no_pi_4-500_bmc64.vkm"
            # Set Raspberry Pi OS keyboard to Norwegian
            sudo raspi-config nonint do_configure_keyboard no
            ;;
        "C64P - Original C64")
            crudini --set "$VICERC" "$section" KeymapIndex 1
            crudini --set "$VICERC" "$section" KeymapUserPosFile "$VICE_SHARE_DATA_DIR/C64/sdl_c64p.vkm"
            # Set Raspberry Pi OS keyboard to US for C64P
            sudo raspi-config nonint do_configure_keyboard us
            ;;
    esac

    # Remove spaces around = for all settings in the file
    sed -i 's/^\([A-Za-z0-9_]\+\) *= */\1=/' "$VICERC"
}

get_joyport_setup() {
    local emu section jd1 jd2 jp1
    emu=$(get_current_bash_profile_emulator)
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
    emu=$(get_current_bash_profile_emulator)
    section=$(get_vicerc_section "$emu")
    [ -z "$section" ] && return

    case "$1" in
        "J1-J2 USB")
            crudini --del "$VICERC" "$section" JoyPort1Device
            crudini --del "$VICERC" "$section" JoyPort2Device
            crudini --set "$VICERC" "$section" JoyDevice1 4
            crudini --set "$VICERC" "$section" JoyDevice2 4
            ;;
        "M1-J2 USB")
            crudini --set "$VICERC" "$section" JoyPort1Device 3
            crudini --del "$VICERC" "$section" JoyPort2Device
            crudini --del "$VICERC" "$section" JoyDevice1
            crudini --set "$VICERC" "$section" JoyDevice2 4
            ;;
        "J1-J2 GPIO")
            crudini --del "$VICERC" "$section" JoyPort1Device
            crudini --del "$VICERC" "$section" JoyPort2Device
            crudini --set "$VICERC" "$section" JoyDevice1 2
            crudini --set "$VICERC" "$section" JoyDevice2 3
            ;;
        "M1-J2 USB/GPIO")
            crudini --set "$VICERC" "$section" JoyPort1Device 3
            crudini --del "$VICERC" "$section" JoyPort2Device
            crudini --del "$VICERC" "$section" JoyDevice1
            crudini --set "$VICERC" "$section" JoyDevice2 3
            ;;
    esac

    # Remove spaces around = for all settings in the file
    sed -i 's/^\([A-Za-z0-9_]\+\) *= */\1=/' "$VICERC"
}

while true; do
    CURRENT_EMU=$(get_current_bash_profile_emulator)
    KEYBOARD_LAYOUT=$(get_keyboard_layout)
    JOYPORT_SETUP=$(get_joyport_setup)
    CHOICE=$(whiptail --title "VICE Pi Menu" \
        --ok-button "Select" --cancel-button "Exit" \
        --menu "Choose an option:" 24 80 13 \
        "1" "Set emulator to launch (current: ${CURRENT_EMU:-none})" \
        "2" "Launch current emulator" \
        "3" "Select Pi keyboard layout (current: ${KEYBOARD_LAYOUT})" \
        "4" "Select joyport setup (current: ${JOYPORT_SETUP})" \
        "5" "Launch Midnight Commander file manager" \
        "6" "Start Samba (Windows file sharing)" \
        "7" "Stop Samba (Windows file sharing)" \
        "8" "Update vice-menu & Makefile" \
        "9" "Launch raspi-config" \
        "10" "Set Pi to auto-login without a password" \
        "11" "Reboot Raspberry Pi" \
        "12" "Shutdown Raspberry Pi" 3>&1 1>&2 2>&3)

    case $CHOICE in
        1)
            EMU=$(whiptail --title "Select Emulator" --default-item "${CURRENT_EMU:-x64}" \
                    --menu "Choose emulator to launch:" 15 50 2 \
                    "x64" "C64 emulator (fast, Pi400)" \
                    "x64sc" "C64 emulator (cycle exact, Pi500)" 3>&1 1>&2 2>&3)
            if [ -n "$EMU" ]; then
                set_bash_profile_emulator "$EMU"
                # Immediately update variables for the new selection
                CURRENT_EMU="$EMU"
                KEYBOARD_LAYOUT=$(get_keyboard_layout)
                JOYPORT_SETUP=$(get_joyport_setup)
                whiptail --msgbox "Set emulator to $EMU in ~/.bash_profile" 8 40
            fi
            ;;
        2)
            EMU=$(get_current_bash_profile_emulator)
            if [ -n "$EMU" ]; then
                "$VICE_INSTALL_DIR/bin/$EMU"
            else
                whiptail --msgbox "No emulator set in ~/.bash_profile" 8 40
            fi
            ;;
        3)
            KEYB=$(whiptail --title "Select Pi Keyboard Layout" --default-item "${KEYBOARD_LAYOUT:-Pi400/Pi500 UK}" \
                --menu "Choose keyboard layout:" 15 70 4 \
                "Pi400/Pi500 UK" "UK keyboard layout for Pi400/Pi500" \
                "Pi400/Pi500 US" "US keyboard layout for Pi400/Pi500" \
                "Pi400/Pi500 NO" "Norwegian keyboard layout for Pi400/Pi500" \
                "C64P - Original C64" "Original C64 keyboard layout" 3>&1 1>&2 2>&3)
            if [ -n "$KEYB" ]; then
                set_keyboard_layout "$KEYB"
                whiptail --msgbox "Keyboard layout set to $KEYB in sdl-vicerc" 8 50
            fi
            ;;
        4)
            JOY=$(whiptail --title "Select Joyport Setup" --default-item "${JOYPORT_SETUP:-J1-J2 USB}" \
                --menu "Choose joyport setup:" 15 70 4 \
                "J1-J2 USB" "Both joysticks on USB" \
                "M1-J2 USB" "Mouse (port 1) on USB, Joystick (port 2) on USB" \
                "J1-J2 GPIO" "Both joysticks on GPIO" \
                "M1-J2 USB/GPIO" "Mouse (port 1) on USB, Joystick (port 2) on GPIO" 3>&1 1>&2 2>&3)
            if [ -n "$JOY" ]; then
                set_joyport_setup "$JOY"
                whiptail --msgbox "Joyports set to $JOY in sdl-vicerc" 8 40
            fi
            ;;
        5)
            mc
            ;;
        6)
            sudo systemctl start smbd
            whiptail --msgbox "Samba started." 8 40
            ;;
        7)
            sudo systemctl stop smbd
            whiptail --msgbox "Samba stopped." 8 40
            ;;
        8)
            if whiptail --yesno "Do you want to update this script and Makefile from the git repository?" 10 60; then
                if git -C "$DIR" pull 2> >(GITERR=$(cat); typeset -p GITERR >&2); then
                    whiptail --msgbox "Update complete. Restarting menu..." 8 40
                    exec "$0"
                else
                    whiptail --msgbox "Git update failed! Please check your network or repository." 12 70
                fi
            fi
            ;;
        9)
            sudo raspi-config
            ;;
        10)
            make -C "$DIR" autologin_pi
            whiptail --msgbox "Auto-login setup complete." 8 40
            ;;
        11)
            if whiptail --yesno "Are you sure you want to reboot the Raspberry Pi?" 8 40; then
                sudo reboot
            fi
            ;;
        12)
            if whiptail --yesno "Are you sure you want to shutdown the Raspberry Pi?" 8 40; then
                sudo shutdown now
            fi
            ;;
        *)
            break
            ;;
    esac
done