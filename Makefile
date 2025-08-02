VICE_VERSION := 3.9
VICE_SRC_DIR := $(HOME)/vice-src
VICE_BUILD_DIR := $(VICE_SRC_DIR)/vice-$(VICE_VERSION)
VICE_INSTALL_DIR := $(HOME)/vice-$(VICE_VERSION)

# OS support dependencies (audio, video, system libraries)
OS_DEPS = \
	pulseaudio alsa-tools

# Build dependencies (compilers, tools, build system)
BUILD_DEPS = \
	git build-essential autoconf automake byacc flex xa65 gawk texinfo \
	dos2unix libpulse-dev libasound2-dev libcurl4-openssl-dev

# VICE-specific dependencies (emulator features, codecs, SDL, etc.)
VICE_DEPS = \
	libpcap-dev libmpg123-dev libvorbis-dev libflac-dev \
	libpng-dev libjpeg-dev portaudio19-dev \
	libsdl2-image-dev libsdl2-dev libsdl2-2.0-0

.PHONY: all deps vice_deps download extract autogen configure build install add_config_txt_changes samba_setup autologin_pi autostart_x64sc clean tools setup_vice_config

all: deps vice_deps download extract autogen configure build install add_config_txt_changes samba_setup autologin_pi autostart_x64sc tools setup_vice_config

deps:
	sudo apt update -y
	sudo apt upgrade -y
	sudo apt-get install -y $(OS_DEPS) $(BUILD_DEPS) $(VICE_DEPS)

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

add_config_txt_changes:
	@echo "Disabling Raspberry Pi rainbow splash screen in /boot/config.txt or /boot/firmware/config.txt..."
	@if [ -f /boot/firmware/config.txt ]; then \
		sudo sed -i '/^disable_splash=/d' /boot/firmware/config.txt; \
		echo "disable_splash=1" | sudo tee -a /boot/firmware/config.txt; \
		echo "Rainbow splash screen will be hidden on next boot (set in /boot/firmware/config.txt)."; \
	else \
		sudo sed -i '/^disable_splash=/d' /boot/config.txt; \
		echo "disable_splash=1" | sudo tee -a /boot/config.txt; \
		echo "Rainbow splash screen will be hidden on next boot (set in /boot/config.txt)."; \
	fi

samba_setup:
	sudo apt-get update
	sudo apt-get install -y samba
	mkdir -p ~/vice-share/disks ~/vice-share/roms
	# Remove any existing [VICE] section
	sudo sed -i '/^\[VICE\]/,/^$$/d' /etc/samba/smb.conf
	# Add the new [VICE] section at the end
	echo "[VICE]\n   path = $$HOME/vice-share\n   browseable = yes\n   read only = no\n   guest ok = no\n   create mask = 0775\n   directory mask = 0775" | sudo tee -a /etc/samba/smb.conf
	chmod 775 ~/vice-share ~/vice-share/disks ~/vice-share/roms
	sudo smbpasswd -a pi
	sudo systemctl restart smbd
	@ip_addr=$$(hostname -I | awk '{print $$1}'); \
	echo "Samba share 'VICE' is set up at $$HOME/vice-share with 'disks' and 'roms' subfolders. Access it from another computer using: smb://pi@$${ip_addr}/VICE (login as user 'pi')"

autologin_pi:
	sudo raspi-config nonint do_boot_behaviour B2
	@echo "Console autologin enabled via raspi-config. Reboot to take effect."

autostart_x64sc:
	@echo "Adding x64sc to ~/.bash_profile for auto-launch on login..."
	echo 'if [ -z "$$SSH_CONNECTION" ]; then' >> $$HOME/.bash_profile
	echo '  $(VICE_INSTALL_DIR)/bin/x64sc' >> $$HOME/.bash_profile
	echo 'fi' >> $$HOME/.bash_profile
	@echo "x64sc will now launch automatically when you log in on the console."

tools:
	sudo apt-get update
	sudo apt-get install -y mc
	@echo "Midnight Commander (mc) and other useful tools have been installed."

setup_vice_config:
	mkdir -p $$HOME/.config/vice
	cp sdl-vicerc $$HOME/.config/vice/
	@echo "Default VICE config (sdl-vicerc) copied to $$HOME/.config/vice/"

clean:
	rm -rf $(VICE_SRC_DIR)

