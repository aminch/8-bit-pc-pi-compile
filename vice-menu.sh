#!/bin/bash

# Vice install dir
VICE_VERSION="3.9"
VICE_INSTALL_DIR=$HOME/vice-$VICE_VERSION

# Path to this scripts directory
DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"

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

while true; do
	CURRENT_EMU=$(get_current_bash_profile_emulator)
	CHOICE=$(whiptail --title "VICE Pi Menu" \
		--ok-button "Select" --cancel-button "Exit" \
		--menu "Choose an option:" 24 80 12 \
		"1" "Set emulator to launch (current: ${CURRENT_EMU:-none})" \
		"2" "Launch current emulator" \
		"3" "Launch Midnight Commander file manager" \
		"4" "Start Samba (Windows file sharing)" \
        "5" "Stop Samba (Windows file sharing)" \
        "6" "Update vice-menu & Makefile" \
        "7" "Launch raspi-config" \
		"8" "Set Pi to auto-login without a password" \
        "9" "Reboot Raspberry Pi" \
        "10" "Shutdown Raspberry Pi" 3>&1 1>&2 2>&3)

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
			mc
			;;
		4)
			sudo systemctl start smbd
			whiptail --msgbox "Samba started." 8 40
			;;
		5)
			sudo systemctl stop smbd
			whiptail --msgbox "Samba stopped." 8 40
			;;
		6)
            if whiptail --yesno "Do you want to update this script and Makefile from the git repository?" 10 60; then
                if git -C "$DIR" pull 2> >(GITERR=$(cat); typeset -p GITERR >&2); then
                    whiptail --msgbox "Update complete. Restarting menu..." 8 40
                    exec "$0"
                else
                    whiptail --msgbox "Git update failed! Please check your network or repository." 12 70
                fi
            fi
            ;;
        7)
            sudo raspi-config
            ;;
		8)
			make -C "$DIR" autologin_pi
			whiptail --msgbox "Auto-login setup complete." 8 40
			;;
        9)
            if whiptail --yesno "Are you sure you want to reboot the Raspberry Pi?" 8 40; then
                sudo reboot
            fi
            ;;
        10)
            if whiptail --yesno "Are you sure you want to shutdown the Raspberry Pi?" 8 40; then
                sudo shutdown now
            fi
            ;;
		*)
			break
			;;
	esac
done