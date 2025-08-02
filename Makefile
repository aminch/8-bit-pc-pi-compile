VICE_VERSION := 3.9
SDL_VERSION := 2
SDL2_VERSION := 2.32.8
SDL2_TARBALL := SDL$(SDL_VERSION)-$(SDL2_VERSION).tar.gz
SDL2_URL := https://github.com/libsdl-org/SDL/releases/download/release-$(SDL2_VERSION)/$(SDL2_TARBALL)
SDL2_SRC_DIR := $(HOME)/sdl$(SDL_VERSION)-src
SDL2_BUILD_DIR := $(SDL2_SRC_DIR)/SDL$(SDL_VERSION)-$(SDL2_VERSION)
SDL2_INSTALL_DIR := $(HOME)/sdl$(SDL_VERSION)-local

VICE_SRC_DIR := $(HOME)/vice-src
VICE_BUILD_DIR := $(VICE_SRC_DIR)/vice-$(VICE_VERSION)
VICE_INSTALL_DIR := $(HOME)/vice-$(VICE_VERSION)

.PHONY: all deps vice_deps download extract autogen configure build install clean

all: deps vice_deps download extract autogen configure build install

deps:
	sudo apt update -y
	sudo apt upgrade -y
	sudo apt-get install -y lsb-release git dialog wget gcc g++ build-essential unzip xmlstarlet \
		python3-pyudev ca-certificates libasound2-dev libudev-dev libibus-1.0-dev libdbus-1-dev \
		fcitx-libs-dev libsndio-dev libx11-dev libxcursor-dev libxext-dev libxi-dev libxinerama-dev \
		libxkbcommon-dev libxrandr-dev libxss-dev libxt-dev libxv-dev libxxf86vm-dev libgl1-mesa-dev \
		libegl1-mesa-dev libgles2-mesa-dev libgl1-mesa-dev libglu1-mesa-dev libdrm-dev libgbm-dev \
		devscripts debhelper dh-autoreconf libraspberrypi-dev libpulse-dev bison \
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
		--disable-catweasel --without-pulse --enable-x64 --disable-html-docs --disable-pdf-docs

build:
	cd $(VICE_BUILD_DIR) && make -j $$(nproc)

install:
	cd $(VICE_BUILD_DIR) && make install

clean:
	rm -rf $(VICE_SRC_DIR) $(VICE_INSTALL_DIR) $(SDL2_SRC_DIR) $(SDL2_INSTALL_DIR)
