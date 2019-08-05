#################################################
##                                             ##
##  Bluespec Processor Build Environment       ##
##                                             ##
#################################################

HERE = $(patsubst %/,%,$(dir $(abspath $(MAKEFILE_LIST))))

.PHONY: submodules
submodules:
	@if git submodule status | egrep -q '^[-]|^[+]' ; then \
	    echo "INFO: Need to reinitialize git submodules"; \
	    git submodule update --init --recursive; \
	fi
