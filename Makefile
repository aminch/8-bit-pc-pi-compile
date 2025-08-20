###############################################################################
# Root Makefile orchestrator (includes split component makefiles)
###############################################################################

include common.mk
include vice.mk
include atari.mk

.PHONY: all default vice atari

all: vice_all ## Default 'all' runs full VICE pipeline (legacy behaviour)
default: all
vice: vice_all ## Alias
atari: atari_all ## Placeholder Atari build

# The help target is defined in common.mk and will list targets from all included files.


