VICE_VERSION := 3.9
VICE_SRC_DIR := $(HOME)/vice-src
VICE_BUILD_DIR := $(VICE_SRC_DIR)/vice-$(VICE_VERSION)
VICE_INSTALL_DIR := $(HOME)/vice-$(VICE_VERSION)
VICE_SHARE_DIR := $(HOME)/vice-share
VICE_APP := x64sc

# Detect Pi 4 family and override variables as needed
ifeq ($(shell model=$$(tr -d "\0" < /proc/device-tree/model); echo $$model | grep -Eq "Raspberry Pi 4|Raspberry Pi 400|Compute Module 4" && echo yes),yes)
VICE_APP := x64
endif

# Set the location of the config.txt file checking firmware directory first
ifeq ($(shell test -d /boot/firmware && echo yes),yes)
CONFIG_FILE := /boot/firmware/config.txt
else
# Fallback to the standard config.txt location
CONFIG_FILE := /boot/config.txt
endif

# OS support dependencies (audio, video, system libraries)
OS_DEPS = \
	pulseaudio alsa-tools crudini

# Build dependencies (compilers, tools, build system)
BUILD_DEPS = \
	git build-essential autoconf automake byacc flex xa65 gawk texinfo \
	dos2unix libpulse-dev libasound2-dev libcurl4-openssl-dev

# VICE-specific dependencies (emulator features, codecs, SDL, etc.)
VICE_DEPS = \
	libpcap-dev libmpg123-dev libvorbis-dev libflac-dev \
	libpng-dev libjpeg-dev portaudio19-dev \
	libsdl2-image-dev libsdl2-dev libsdl2-2.0-0

.PHONY: all deps download extract autogen configure build install update_config samba_setup autologin_pi autostart clean tools setup_vice_config copy_vice_config install_menu reboot

all: deps autologin_pi download extract autogen configure build install update_config samba_setup autostart tools setup_vice_config copy_vice_config install_menu reboot

deps:
	sudo apt update -y
	sudo apt upgrade -y
	sudo apt-get install -y $(OS_DEPS) $(BUILD_DEPS) $(VICE_DEPS)

autologin_pi:
	sudo raspi-config nonint do_boot_behaviour B2
	@echo "Console autologin enabled via raspi-config."

download:
	mkdir -p $(VICE_SRC_DIR)
	wget -O $(VICE_SRC_DIR)/vice-$(VICE_VERSION).tar.gz https://sourceforge.net/projects/vice-emu/files/releases/vice-$(VICE_VERSION).tar.gz/download

extract:
	tar -xvf $(VICE_SRC_DIR)/vice-$(VICE_VERSION).tar.gz -C $(VICE_SRC_DIR)

autogen:
	cd $(VICE_BUILD_DIR) && ./autogen.sh

configure:
	cd $(VICE_BUILD_DIR) && ./configure --prefix=$(VICE_INSTALL_DIR) --enable-sdl2ui --without-oss --enable-ethernet \
		--disable-catweasel  --with-pulse --with-resid --enable-x64 --disable-html-docs --disable-pdf-docs

build:
	cd $(VICE_BUILD_DIR) && make -j $$(nproc)

install:
	cd $(VICE_BUILD_DIR) && make install

update_config:
	@echo "Disabling Raspberry Pi rainbow splash screen in config.txt..."
	@sudo sed -i '/^disable_splash=/d' $(CONFIG_FILE)
	@if ! grep -q '^disable_splash=1' $(CONFIG_FILE); then \
		LINE=$$(grep -n '^\[' $(CONFIG_FILE) | head -n1 | cut -d: -f1); \
		echo "disable_splash=1" > /tmp/vice-tmp.txt; \
		echo "" >> /tmp/vice-tmp.txt; \
		if [ -n "$$LINE" ]; then \
			sudo sed -i "$$((LINE-1))r /tmp/vice-tmp.txt" $(CONFIG_FILE); \
		else \
			sudo tee -a $(CONFIG_FILE) < /tmp/vice-tmp.txt > /dev/null; \
		fi; \
		rm -f /tmp/vice-tmp.txt; \
		echo "Added disable_splash=1 to $(CONFIG_FILE)."; \
	else \
		echo "disable_splash=1 already present in $(CONFIG_FILE)."; \
	fi
	@echo "Checking for existing GPIO joystick key overlays..."
	@if ! grep -q "dtoverlay=gpio-key,gpio=17,active_low=1,gpio_pull=up,keycode=73" $(CONFIG_FILE); then \
		LINE=$$(grep -n '^\[' $(CONFIG_FILE) | head -n1 | cut -d: -f1); \
		cat gpio-keys.txt > /tmp/gpio-keys-block.txt; \
		echo "" >> /tmp/gpio-keys-block.txt; \
		if [ -n "$$LINE" ]; then \
			sudo sed -i "$$((LINE-1))r /tmp/gpio-keys-block.txt" $(CONFIG_FILE); \
		else \
			sudo tee -a $(CONFIG_FILE) < /tmp/gpio-keys-block.txt > /dev/null; \
		fi; \
		rm -f /tmp/gpio-keys-block.txt; \
		echo "GPIO joystick key overlays added to $(CONFIG_FILE)."; \
	else \
		echo "GPIO joystick key overlays already present in $(CONFIG_FILE)."; \
	fi

samba_setup:
	sudo apt-get update
	sudo apt-get install -y samba
	mkdir -p $(VICE_SHARE_DIR)/disks $(VICE_SHARE_DIR)/roms $(VICE_SHARE_DIR)/data
	# Remove any existing [VICE] section
	sudo sed -i '/^\[VICE\]/,/^$$/d' /etc/samba/smb.conf
	# Add the new [VICE] section at the end
	echo "[VICE]\n   path = $(VICE_SHARE_DIR)\n   browseable = yes\n   read only = no\n   guest ok = no\n   create mask = 0775\n   directory mask = 0775" | sudo tee -a /etc/samba/smb.conf
	chmod 775 $(VICE_SHARE_DIR) $(VICE_SHARE_DIR)/disks $(VICE_SHARE_DIR)/roms $(VICE_SHARE_DIR)/data
	@echo "You will need to set a Samba password for the 'pi' user:"
	sudo smbpasswd -a pi
	sudo systemctl restart smbd
	@ip_addr=$$(hostname -I | awk '{print $$1}'); \
	echo "Samba share 'VICE' is set up at $(VICE_SHARE_DIR) with 'disks', 'roms', and 'data' subfolders. Access it from another computer using: smb://pi@$${ip_addr}/VICE (login as user 'pi')"

autostart:
	@echo "Configuring VICE autostart in ~/.bash_profile..."
	@test -f $(HOME)/.bash_profile || touch $(HOME)/.bash_profile
	@sed -i '/# VICE AUTOSTART START/,/# VICE AUTOSTART END/d' $(HOME)/.bash_profile || true
	@echo "# VICE AUTOSTART START" >> $(HOME)/.bash_profile
	@echo "if [ -z \"\$$SSH_CONNECTION\" ]; then" >> $(HOME)/.bash_profile
	@echo "  $(VICE_INSTALL_DIR)/bin/$(VICE_APP)" >> $(HOME)/.bash_profile
	@echo "fi" >> $(HOME)/.bash_profile
	@echo "# VICE AUTOSTART END" >> $(HOME)/.bash_profile
	@echo "Configured to auto-start $(VICE_APP) in ~/.bash_profile."

tools:
	sudo apt-get update
	sudo apt-get install -y mc
	@echo "Midnight Commander (mc) and other useful tools have been installed."

setup_vice_config:
	mkdir -p $$HOME/.config/vice
	cp sdl-vicerc $$HOME/.config/vice/
	@echo "Default VICE config (sdl-vicerc) copied to $$HOME/.config/vice/"

copy_vice_config:
	mkdir -p $(VICE_SHARE_DIR)/data/C64
	cp -rf $(PWD)/data/C64/* $(VICE_SHARE_DIR)/data/C64/
	@echo "Copied all data files from $(PWD)/data/C64/* to $(VICE_SHARE_DIR)/data/C64/"

install_menu:
	@echo "Making vice-menu.sh executable..."
	chmod +x $(PWD)/vice-menu.sh
	@echo "Installing vice-menu.sh symlink to /usr/local/bin/vice-menu..."
	sudo ln -sf $(PWD)/vice-menu.sh /usr/local/bin/vice-menu
	@echo "You can now run 'vice-menu' from anywhere."

reboot:	
	@bash -c 'read -n 1 -s -r -p "Press any key to reboot to finalise set up..."; echo; sudo reboot'

clean:
	rm -rf $(VICE_SRC_DIR)

