# ---------------- VICE build / install layer ----------------
.PHONY: vice_all vice_body vice_deps vice_download vice_extract vice_patch vice_autogen vice_configure vice_build vice_install setup_vice_config copy_vice_data

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

setup_vice_config: ## Copy default sdl-vicerc user config
	mkdir -p $$HOME/.config/vice
	cp sdl-vicerc $$HOME/.config/vice/
	@echo "Default VICE config copied to $$HOME/.config/vice/"

copy_vice_data: ## Copy supplied data files into share
	mkdir -p $(VICE_SHARE_DIR)/data/C64
	cp -rf $(PWD)/data/C64/* $(VICE_SHARE_DIR)/data/C64/
	@echo "Copied data files to $(VICE_SHARE_DIR)/data/C64/"

vice_body: ## VICE-only steps (no common phases)
	$(MAKE) vice_deps vice_download vice_extract vice_patch vice_autogen vice_configure vice_build vice_install setup_vice_config copy_vice_data

vice_all: ## Full VICE pipeline including common pre/post phases
	$(MAKE) common_pre
	$(MAKE) vice_body
	$(MAKE) common_post
