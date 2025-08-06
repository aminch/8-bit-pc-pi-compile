#!/bin/bash

# Vice install dir
VICE_VERSION="3.9"
VICE_INSTALL_DIR=$HOME/vice-$VICE_VERSION

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
        x64sc) echo "C64SC" ;;
        x64)   echo "C64" ;;
        # Add more mappings as needed
        *)     echo "" ;;
    esac
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
}

while true; do
	CURRENT_EMU=$(get_current_bash_profile_emulator)
	JOYPORT_SETUP=$(get_joyport_setup)	
	CHOICE=$(whiptail --title "VICE Pi Menu" \
		--ok-button "Select" --cancel-button "Exit" \
		--menu "Choose an option:" 24 80 12 \
		"1" "Set emulator to launch (current: ${CURRENT_EMU:-none})" \
		"2" "Launch current emulator" \
        "3" "Select joyport setup (current: ${JOYPORT_SETUP})" \
		"4" "Launch Midnight Commander file manager" \
		"5" "Start Samba (Windows file sharing)" \
        "6" "Stop Samba (Windows file sharing)" \
        "7" "Update vice-menu & Makefile" \
        "8" "Launch raspi-config" \
		"9" "Set Pi to auto-login without a password" \
        "10" "Reboot Raspberry Pi" \
        "11" "Shutdown Raspberry Pi" 3>&1 1>&2 2>&3)

	case $CHOICE in
		1)
			EMU=$(whiptail --title "Select Emulator" --menu "Choose emulator to launch:" 15 50 2 \
				"x64" "C64 emulator (fast, Pi400)" \
				"x64sc" "C64 emulator (cycle exact, Pi500)" 3>&1 1>&2 2>&3)
			if [ -n "$EMU" ]; then
				set_bash_profile_emulator "$EMU"
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
            JOY=$(whiptail --title "Select Joyport Setup" --menu "Choose joyport setup:" 15 70 4 \
                "J1-J2 USB" "Both joysticks on USB" \
                "M1-J2 USB" "Mouse (port 1) on USB, Joystick (port 2) on USB" \
                "J1-J2 GPIO" "Both joysticks on GPIO" \
                "M1-J2 USB/GPIO" "Mouse (port 1) on USB, Joystick (port 2) on GPIO" 3>&1 1>&2 2>&3)
            if [ -n "$JOY" ]; then
                set_joyport_setup "$JOY"
                whiptail --msgbox "Joyports set to $JOY in sdl-vicerc" 8 40
            fi
            ;;
		4)
			mc
			;;
		5)
			sudo systemctl start smbd
			whiptail --msgbox "Samba started." 8 40
			;;
		6)
			sudo systemctl stop smbd
			whiptail --msgbox "Samba stopped." 8 40
			;;
		7)
            if whiptail --yesno "Do you want to update this script and Makefile from the git repository?" 10 60; then
                if git -C "$DIR" pull 2> >(GITERR=$(cat); typeset -p GITERR >&2); then
                    whiptail --msgbox "Update complete. Restarting menu..." 8 40
                    exec "$0"
                else
                    whiptail --msgbox "Git update failed! Please check your network or repository." 12 70
                fi
            fi
            ;;
        8)
            sudo raspi-config
            ;;
		9)
			make -C "$DIR" autologin_pi
			whiptail --msgbox "Auto-login setup complete." 8 40
			;;
        10)
            if whiptail --yesno "Are you sure you want to reboot the Raspberry Pi?" 8 40; then
                sudo reboot
            fi
            ;;
        11)
            if whiptail --yesno "Are you sure you want to shutdown the Raspberry Pi?" 8 40; then
                sudo shutdown now
            fi
            ;;
		*)
			break
			;;
	esac
done