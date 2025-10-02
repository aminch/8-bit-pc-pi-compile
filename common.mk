.PHONY: deps samba_setup autologin_pi tools install_menu post_install_message update_config update_cmdline reboot clean help common_pre common_post

# Shared directories
SHARE_DIR := $(HOME)/share

# Pick config.txt path
ifeq ($(shell test -d /boot/firmware && echo yes),yes)
CONFIG_FILE := /boot/firmware/config.txt
CMDLINE_FILE := /boot/firmware/cmdline.txt
else
CONFIG_FILE := /boot/config.txt
CMDLINE_FILE := /boot/cmdline.txt
endif

# HDMI video setting start with 720p to be conservative
VIDEO_SETTING := video=HDMI-A-1:1280x720M@60

# Common dependencies (system + build)
OS_DEPS = pulseaudio alsa-tools crudini exfat-fuse exfatprogs ntfs-3g fastfetch
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
	sudo apt-get install -y samba
	mkdir -p $(SHARE_DIR)/disks $(SHARE_DIR)/roms $(SHARE_DIR)/data
	# Remove existing SHARE block
	sudo sed -i '/^\[SHARE\]/,/^$$/d' /etc/samba/smb.conf
	# Append new block
	echo "[SHARE]\n   path = $(SHARE_DIR)\n   browseable = yes\n   read only = no\n   guest ok = no\n   create mask = 0775\n   directory mask = 0775" | sudo tee -a /etc/samba/smb.conf
	chmod 775 $(SHARE_DIR) $(SHARE_DIR)/disks $(SHARE_DIR)/roms $(SHARE_DIR)/data
	@echo "Set a Samba password for user 'pi' if prompted."
	sudo smbpasswd -a pi || true
	sudo systemctl restart smbd
	@ip_addr=$$(hostname -I | awk '{print $$1}'); echo "Samba share at smb://pi@$$ip_addr/SHARE"

autologin_pi: ## Enable console auto-login for current user (Raspberry Pi OS)
	sudo raspi-config nonint do_boot_behaviour B2
	@echo "Console autologin enabled."

tools: ## Install general tools (Midnight Commander)
	sudo apt-get install -y mc
	@echo "Installed Midnight Commander (mc)."

install_menu: ## Install launcher script to /usr/local/bin/menu
	chmod +x $(PWD)/menu.sh
	sudo ln -sf $(PWD)/menu.sh /usr/local/bin/menu
	@echo "Launcher installed: run 'menu'"

update_config: ## Update Pi firmware config (splash + GPIO overlay)
	@echo "Disabling Raspberry Pi rainbow splash screen in config.txt..."
	@sudo sed -i '/^disable_splash=/d' $(CONFIG_FILE)
	@if ! grep -q '^disable_splash=1' $(CONFIG_FILE); then \
		LINE=$$(grep -n '^\[' $(CONFIG_FILE) | head -n1 | cut -d: -f1); \
		echo "disable_splash=1" > /tmp/config-tmp.txt; echo "" >> /tmp/config-tmp.txt; \
		if [ -n "$$LINE" ]; then sudo sed -i "$$((LINE-1))r /tmp/config-tmp.txt" $(CONFIG_FILE); else sudo tee -a $(CONFIG_FILE) < /tmp/config-tmp.txt > /dev/null; fi; \
		rm -f /tmp/config-tmp.txt; echo "Added disable_splash=1 to $(CONFIG_FILE)."; \
	else echo "disable_splash=1 already present in $(CONFIG_FILE)."; fi
	@echo "Checking for existing GPIO joystick key overlays..."
	@if ! grep -q "dtoverlay=gpio-key,gpio=17,active_low=1,gpio_pull=up,keycode=73" $(CONFIG_FILE); then \
		LINE=$$(grep -n '^\[' $(CONFIG_FILE) | head -n1 | cut -d: -f1); \
		cat gpio-keys.txt > /tmp/gpio-keys-block.txt; echo "" >> /tmp/gpio-keys-block.txt; \
		if [ -n "$$LINE" ]; then sudo sed -i "$$((LINE-1))r /tmp/gpio-keys-block.txt" $(CONFIG_FILE); else sudo tee -a $(CONFIG_FILE) < /tmp/gpio-keys-block.txt > /dev/null; fi; \
		rm -f /tmp/gpio-keys-block.txt; echo "GPIO joystick key overlays added to $(CONFIG_FILE)."; \
	else echo "GPIO joystick key overlays already present in $(CONFIG_FILE)."; fi

update_cmdline: ## Update cmdline.txt with video parameters
	@echo "Updating cmdline.txt with HDMI video parameters..."
	@if grep -q "$(VIDEO_SETTING)" $(CMDLINE_FILE); then \
		echo "$(VIDEO_SETTING) already present in $(CMDLINE_FILE)."; \
	else \
		sudo sed -i '/video=HDMI-A-1:/d' $(CMDLINE_FILE); \
		sudo sed -i 's/$$/ $(VIDEO_SETTING)/' $(CMDLINE_FILE); \
		echo "Added $(VIDEO_SETTING) to $(CMDLINE_FILE)."; \
	fi

post_install_message: ## Final instructions after full build/install
	@echo ""
	@echo "============================================================"
	@echo "Everything is installed."
	@echo "Run: menu after the reboot to select your default emulator."
	@echo "============================================================"
	@echo ""

reboot: ## Prompt then reboot to finalise setup
	@bash -c 'read -n 1 -s -r -p "Press any key to reboot..."; echo; sudo reboot'

# Grouped common phases for reuse
common_pre: ## Run shared pre-build setup (deps, samba, tools)
	$(MAKE) deps

common_post: ## Run shared post-build steps (install menu + final message)
	$(MAKE)  update_config update_cmdline samba_setup autologin_pi tools install_menu post_install_message reboot

clean: ## Remove downloaded source trees (VICE & Atari)
	rm -rf $(HOME)/vice-src $(HOME)/atari-src
