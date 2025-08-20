.PHONY: deps samba_setup autologin_pi tools install_menu post_install_message reboot clean help

# Shared directories
SHARE_DIR := $(HOME)/share

# Common dependencies (system + build)
OS_DEPS = pulseaudio alsa-tools crudini
BUILD_DEPS = git build-essential autoconf automake byacc flex xa65 gawk texinfo \
	 dos2unix libpulse-dev libasound2-dev libcurl4-openssl-dev

# Generic helper for help target (target descriptions come from trailing ## comments)
help: ## Show this help
	@grep -hE '^[a-zA-Z0-9_.-]+:.*?##' $(MAKEFILE_LIST) | awk 'BEGIN{FS":.*?## "}{printf "\033[36m%-28s\033[0m %s\n", $$1, $$2}' | sort

# Install common deps (VICE / Atari layer add their own extras)
deps: ## Install common system & build dependencies
	sudo apt update -y && sudo apt upgrade -y
	sudo apt-get install -y $(OS_DEPS) $(BUILD_DEPS)

samba_setup: ## Install & configure Samba share at $(SHARE_DIR)
	sudo apt-get update
	sudo apt-get install -y samba
	mkdir -p $(SHARE_DIR)/disks $(SHARE_DIR)/roms $(SHARE_DIR)/data
	# Remove existing VICE share block
	sudo sed -i '/^\[VICE\]/,/^$$/d' /etc/samba/smb.conf
	# Append new block
	echo "[VICE]\n   path = $(SHARE_DIR)\n   browseable = yes\n   read only = no\n   guest ok = no\n   create mask = 0775\n   directory mask = 0775" | sudo tee -a /etc/samba/smb.conf
	chmod 775 $(SHARE_DIR) $(SHARE_DIR)/disks $(SHARE_DIR)/roms $(SHARE_DIR)/data
	@echo "Set a Samba password for user 'pi' if prompted."
	sudo smbpasswd -a pi || true
	sudo systemctl restart smbd
	@ip_addr=$$(hostname -I | awk '{print $$1}'); echo "Samba share at smb://pi@$$ip_addr/VICE"

autologin_pi: ## Enable console auto-login for current user (Raspberry Pi OS)
	sudo raspi-config nonint do_boot_behaviour B2
	@echo "Console autologin enabled."

tools: ## Install general tools (Midnight Commander)
	sudo apt-get update
	sudo apt-get install -y mc
	@echo "Installed Midnight Commander (mc)."

install_menu: ## Install launcher script to /usr/local/bin/menu
	chmod +x $(PWD)/menu.sh
	sudo ln -sf $(PWD)/menu.sh /usr/local/bin/menu
	@echo "Launcher installed: run 'menu'"

post_install_message: ## Final instructions after full build/install
	@echo ""
	@echo "============================================================"
	@echo "Everything is installed."
	@echo "Run: menu after the reboot to select your default emulator."
	@echo "============================================================"
	@echo ""

reboot: ## Prompt then reboot to finalise setup
	@bash -c 'read -n 1 -s -r -p "Press any key to reboot..."; echo; sudo reboot'

clean: ## Remove downloaded source trees (VICE & Atari)
	rm -rf $(HOME)/vice-src $(HOME)/atari-src
