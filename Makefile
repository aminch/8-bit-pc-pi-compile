###############################################################################
# Root Makefile orchestrator (includes split component makefiles)
###############################################################################

include common.mk
include vice.mk
include atari.mk

.PHONY: all default vice atari everything

# Build BOTH VICE and Atari by default
all: everything ## Build and install VICE and Atari plus menu (default)
default: all

everything: vice_all atari_all ## Full multi-emulator environment
vice: vice_all ## VICE only
atari: atari_all ## Atari only

# The help target is defined in common.mk and will list targets from all included files.


