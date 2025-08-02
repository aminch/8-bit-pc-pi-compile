VICE_VERSION := 3.9
VICE_SRC_DIR := $(HOME)/vice-src
VICE_BUILD_DIR := $(VICE_SRC_DIR)/vice-$(VICE_VERSION)
VICE_INSTALL_DIR := $(HOME)/vice-$(VICE_VERSION)

.PHONY: all deps vice_deps download extract autogen configure build install samba_setup autologin_pi autostart_x64sc clean

all: deps vice_deps download extract autogen configure build install samba_setup autologin_pi autostart_x64sc

deps:
	sudo apt update -y
	sudo apt upgrade -y
	sudo apt-get install -y lsb-release git dialog wget gcc g++ build-essential unzip xmlstarlet \
		python3-pyudev ca-certificates libasound2-dev libudev-dev libibus-1.0-dev libdbus-1-dev \
		fcitx-libs-dev libsndio-dev libx11-dev libxcursor-dev libxext-dev libxi-dev libxinerama-dev \
		libxkbcommon-dev libxrandr-dev libxss-dev libxt-dev libxv-dev libxxf86vm-dev libgl1-mesa-dev \
		libegl1-mesa-dev libgles2-mesa-dev libgl1-mesa-dev libglu1-mesa-dev libdrm-dev libgbm-dev \
		devscripts debhelper dh-autoreconf libraspberrypi-dev libpulse-dev bison flex xa65 \
		libcurl4-openssl-dev pulseaudio pulseaudio-dev \
		autoconf automake libtool pkg-config libsdl2-dev

download:
	mkdir -p $(VICE_SRC_DIR)
	wget -O $(VICE_SRC_DIR)/vice-$(VICE_VERSION).tar.gz https://sourceforge.net/projects/vice-emu/files/releases/vice-$(VICE_VERSION).tar.gz/download

extract:
	tar -xvf $(VICE_SRC_DIR)/vice-$(VICE_VERSION).tar.gz -C $(VICE_SRC_DIR)

autogen:
	cd $(VICE_BUILD_DIR) && ./autogen.sh

configure:
	cd $(VICE_BUILD_DIR) && ./configure --prefix=$(VICE_INSTALL_DIR) --enable-sdl2ui --without-oss --enable-ethernet \
		--disable-catweasel  --with-pulse --enable-x64 --disable-html-docs --disable-pdf-docs

build:
	cd $(VICE_BUILD_DIR) && make -j $$(nproc)

install:
	cd $(VICE_BUILD_DIR) && make install

samba_setup:
	sudo apt-get update
	sudo apt-get install -y samba
	mkdir -p ~/vice-share
	echo "[VICE]\n   path = $$HOME/vice-share\n   browseable = yes\n   read only = no\n   guest ok = yes\n   create mask = 0775\n   directory mask = 0775" | sudo tee -a /etc/samba/smb.conf
	chmod 775 ~/vice-share
	sudo systemctl restart smbd
	@echo "Samba share 'VICE' is set up at $$HOME/vice-share. Access it from another computer using: smb://<your-pi-ip-address>/VICE"

autologin_pi:
	@echo "Setting up auto-login for user '$$USER'..."
	sudo sed -i '/^#*autologin-user=/c\autologin-user=$$USER' /etc/lightdm/lightdm.conf
	sudo sed -i '/^#*autologin-user-timeout=/c\autologin-user-timeout=0' /etc/lightdm/lightdm.conf
	@echo "Auto-login enabled for user '$$USER'. Reboot to take effect."

autostart_x64sc:
	@echo "[Unit]" | sudo tee /etc/systemd/system/x64sc.service
	@echo "Description=VICE x64sc Commodore 64 Emulator (Console)" | sudo tee -a /etc/systemd/system/x64sc.service
	@echo "After=network.target" | sudo tee -a /etc/systemd/system/x64sc.service
	@echo "" | sudo tee -a /etc/systemd/system/x64sc.service
	@echo "[Service]" | sudo tee -a /etc/systemd/system/x64sc.service
	@echo "Type=simple" | sudo tee -a /etc/systemd/system/x64sc.service
	@echo "User=$$USER" | sudo tee -a /etc/systemd/system/x64sc.service
	@echo "Environment=SDL_VIDEODRIVER=fbcon" | sudo tee -a /etc/systemd/system/x64sc.service
	@echo "ExecStart=$(VICE_INSTALL_DIR)/bin/x64sc" | sudo tee -a /etc/systemd/system/x64sc.service
	@echo "Restart=on-failure" | sudo tee -a /etc/systemd/system/x64sc.service
	@echo "" | sudo tee -a /etc/systemd/system/x64sc.service
	@echo "[Install]" | sudo tee -a /etc/systemd/system/x64sc.service
	@echo "WantedBy=multi-user.target" | sudo tee -a /etc/systemd/system/x64sc.service
	sudo systemctl daemon-reload
	sudo systemctl enable x64sc.service
	@echo "x64sc will now launch automatically at boot in console mode. You can start it immediately with: sudo systemctl start x64sc.service"

clean:
	rm -rf $(VICE_SRC_DIR) $(VICE_INSTALL_DIR) $(SDL2_SRC_DIR) $(SDL2_INSTALL_DIR)
