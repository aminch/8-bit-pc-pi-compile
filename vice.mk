# ---------------- VICE build / install layer ----------------
.PHONY: vice_all vice_body vice_deps vice_download vice_extract vice_patch vice_autogen vice_configure vice_build vice_install vice_update_config setup_vice_config copy_vice_data

VICE_VERSION := 3.9
VICE_SRC_DIR := $(HOME)/vice-src
VICE_BUILD_DIR := $(VICE_SRC_DIR)/vice-$(VICE_VERSION)
VICE_INSTALL_DIR := $(HOME)/vice-$(VICE_VERSION)
VICE_SHARE_DIR := $(HOME)/share
VICE_APP := x64sc
PATCH_FILE := $(PWD)/joy-skip-noncontroller.3.9.patch
JOY_SRC_FILE := $(VICE_BUILD_DIR)/src/arch/sdl/joy.c

# Detect Pi 4 family and override default app
ifeq ($(shell model=$$(tr -d "\0" < /proc/device-tree/model); echo $$model | grep -Eq "Raspberry Pi 4|Raspberry Pi 400|Compute Module 4" && echo yes),yes)
VICE_APP := x64
endif

# Pick config.txt path
ifeq ($(shell test -d /boot/firmware && echo yes),yes)
CONFIG_FILE := /boot/firmware/config.txt
else
CONFIG_FILE := /boot/config.txt
endif

# Extra libs VICE needs beyond common deps
VICE_DEPS = libpcap-dev libmpg123-dev libvorbis-dev libflac-dev \
	libpng-dev libjpeg-dev portaudio19-dev \
	libsdl2-image-dev libsdl2-dev libsdl2-2.0-0

vice_deps: ## Install VICE specific dependencies
	sudo apt-get install -y $(VICE_DEPS)

vice_download: ## Download VICE source tarball
	mkdir -p $(VICE_SRC_DIR)
	wget -O $(VICE_SRC_DIR)/vice-$(VICE_VERSION).tar.gz https://sourceforge.net/projects/vice-emu/files/releases/vice-$(VICE_VERSION).tar.gz/download

vice_extract: ## Extract VICE source
	tar -xvf $(VICE_SRC_DIR)/vice-$(VICE_VERSION).tar.gz -C $(VICE_SRC_DIR)

vice_patch: ## Apply joystick patch if not already applied
	@if [ ! -f "$(PATCH_FILE)" ]; then echo "Patch file $(PATCH_FILE) not found."; exit 1; fi
	@echo "Checking joystick patch..."
	@if grep -q 'Ignoring non-controller device' "$(JOY_SRC_FILE)"; then \
		echo "Joystick patch already present; skipping."; \
	else \
		echo "Applying joystick patch..."; \
		cd $(VICE_BUILD_DIR) && patch -p1 < "$(PATCH_FILE)"; \
		echo "Patch applied."; \
	fi

vice_autogen: ## Run autogen for VICE
	cd $(VICE_BUILD_DIR) && ./autogen.sh

vice_configure: ## Configure VICE build
	cd $(VICE_BUILD_DIR) && ./configure --prefix=$(VICE_INSTALL_DIR) --enable-sdl2ui --without-oss --enable-ethernet \
		--disable-catweasel --with-pulse --with-resid --enable-x64 --disable-html-docs --disable-pdf-docs

vice_build: ## Build VICE
	cd $(VICE_BUILD_DIR) && make -j $$(nproc)

vice_install: ## Install VICE
	cd $(VICE_BUILD_DIR) && make install

vice_update_config: ## Update Pi firmware config (splash + GPIO overlay)
	@echo "Disabling Raspberry Pi rainbow splash screen in config.txt..."
	@sudo sed -i '/^disable_splash=/d' $(CONFIG_FILE)
	@if ! grep -q '^disable_splash=1' $(CONFIG_FILE); then \
		LINE=$$(grep -n '^\[' $(CONFIG_FILE) | head -n1 | cut -d: -f1); \
		echo "disable_splash=1" > /tmp/vice-tmp.txt; echo "" >> /tmp/vice-tmp.txt; \
		if [ -n "$$LINE" ]; then sudo sed -i "$$((LINE-1))r /tmp/vice-tmp.txt" $(CONFIG_FILE); else sudo tee -a $(CONFIG_FILE) < /tmp/vice-tmp.txt > /dev/null; fi; \
		rm -f /tmp/vice-tmp.txt; echo "Added disable_splash=1 to $(CONFIG_FILE)."; \
	else echo "disable_splash=1 already present in $(CONFIG_FILE)."; fi
	@echo "Checking for existing GPIO joystick key overlays..."
	@if ! grep -q "dtoverlay=gpio-key,gpio=17,active_low=1,gpio_pull=up,keycode=73" $(CONFIG_FILE); then \
		LINE=$$(grep -n '^\[' $(CONFIG_FILE) | head -n1 | cut -d: -f1); \
		cat gpio-keys.txt > /tmp/gpio-keys-block.txt; echo "" >> /tmp/gpio-keys-block.txt; \
		if [ -n "$$LINE" ]; then sudo sed -i "$$((LINE-1))r /tmp/gpio-keys-block.txt" $(CONFIG_FILE); else sudo tee -a $(CONFIG_FILE) < /tmp/gpio-keys-block.txt > /dev/null; fi; \
		rm -f /tmp/gpio-keys-block.txt; echo "GPIO joystick key overlays added to $(CONFIG_FILE)."; \
	else echo "GPIO joystick key overlays already present in $(CONFIG_FILE)."; fi

setup_vice_config: ## Copy default sdl-vicerc user config
	mkdir -p $$HOME/.config/vice
	cp sdl-vicerc $$HOME/.config/vice/
	@echo "Default VICE config copied to $$HOME/.config/vice/"

copy_vice_data: ## Copy supplied data files into share
	mkdir -p $(VICE_SHARE_DIR)/data/C64
	cp -rf $(PWD)/data/C64/* $(VICE_SHARE_DIR)/data/C64/
	@echo "Copied data files to $(VICE_SHARE_DIR)/data/C64/"

vice_body: ## VICE-only steps (no common phases)
	$(MAKE) vice_deps vice_download vice_extract vice_patch vice_autogen vice_configure vice_build vice_install vice_update_config setup_vice_config copy_vice_data

vice_all: ## Full VICE pipeline including common pre/post phases
	$(MAKE) common_pre
	$(MAKE) vice_body
	$(MAKE) common_post
