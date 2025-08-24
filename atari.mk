# ---------------- Atari build layer ----------------
.PHONY: atari_all atari_body atari_deps atari_clone atari_autogen atari_configure atari_build atari_install atari_copy_config

ATARI_REPO_URL := https://github.com/aminch/atari800-pios-lite.git
ATARI_BRANCH   := pi-os-lite
ATARI_SRC_ROOT := $(HOME)/atari-src
ATARI_BUILD_DIR := $(ATARI_SRC_ROOT)/atari800-pios-lite
ATARI_INSTALL_DIR := $(HOME)/atari800
ATARI_DEFAULT_CFG := $(PWD)/defaults/.atari800.cfg

# Extra libs Atari800 needs beyond common deps
ATARI_DEPS = libsdl2-image-dev libsdl2-dev libsdl2-2.0-0

atari_deps: ## Install Atari specific dependencies
	sudo apt-get install -y $(ATARI_DEPS)

atari_clone: ## Clone / update Atari800 repo (pi-os-lite branch)
	mkdir -p $(ATARI_SRC_ROOT)
	@if [ ! -d "$(ATARI_BUILD_DIR)/.git" ]; then \
		git clone --branch $(ATARI_BRANCH) --depth 1 $(ATARI_REPO_URL) $(ATARI_BUILD_DIR); \
	else \
		cd $(ATARI_BUILD_DIR) && git fetch origin $(ATARI_BRANCH) && git checkout $(ATARI_BRANCH) && git pull; \
	fi

atari_autogen: ## Run autogen.sh for Atari800
	cd $(ATARI_BUILD_DIR) && ./autogen.sh

atari_configure: ## Configure Atari800 with prefix $(ATARI_INSTALL_DIR)
	cd $(ATARI_BUILD_DIR) && ./configure --prefix=$(ATARI_INSTALL_DIR)

atari_build: ## Build Atari800
	cd $(ATARI_BUILD_DIR) && make -j $$(nproc)

atari_install: ## Install Atari800
	cd $(ATARI_BUILD_DIR) && make install

atari_copy_config: ## Copy single default Atari config (.atari.cfg) into HOME if present
	@if [ -f $(ATARI_DEFAULT_CFG) ]; then \
		cp $(ATARI_DEFAULT_CFG) $$HOME/; \
		echo "Copied $(ATARI_DEFAULT_CFG) to $$HOME"; \
	else \
		echo "Config file $(ATARI_DEFAULT_CFG) not found."; \
	fi

atari_body: ## Atari-only steps (no common phases)
	$(MAKE) atari_deps atari_clone atari_autogen atari_configure atari_build atari_install atari_copy_config

atari_all: ## Full Atari pipeline including common pre/post phases
	$(MAKE) common_pre
	$(MAKE) atari_body
	$(MAKE) common_post
