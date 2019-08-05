#################################################
##                                             ##
##  Bluespec Processor Build Environment       ##
##                                             ##
#################################################

HERE = $(patsubst %/,%,$(dir $(abspath $(MAKEFILE_LIST))))

#################################################
##                                             ##
##  Build Controls                             ##
##                                             ##
#################################################

  # where to base most symlinks from
REF_CORE   ?= Flute
COMMON_SRC  = 
#################################################
##                                             ##
##  Directories of Interest                    ##
##                                             ##
#################################################

UPSTREAM     = $(HERE)/upstream-bsv
UPSTREAM_SRC = $(UPSTREAM)/bsv
UPSTREAM_REF = $(UPSTREAM)/$(REF_CORE)

#################################################
##                                             ##
##  Utility Targets                            ##
##                                             ##
#################################################

.PHONY: submodules
submodules:
	@if git submodule status | egrep -q '^[-]|^[+]' ; then \
	    echo "INFO: Need to reinitialize git submodules"; \
	    git submodule update --init --recursive; \
	fi

$(UPSTREAM_SRC): submodules
	@mkdir -p $(UPSTREAM_SRC)

  # below still needs Piccolo and Flute Specific CPU symlinks
.PHONY: symlinks
symlinks: $(UPSTREAM_SRC)
	@ln -s $(UPSTREAM_REF)/src_Core/BSV_Additional_Libs $(UPSTREAM_SRC)/BSV_Additional_Libs
	@ln -s $(UPSTREAM_REF)/src_Core/Core $(UPSTREAM_SRC)/Core
	@ln -s $(UPSTREAM_REF)/src_Core/Debug_Module $(UPSTREAM_SRC)/Debug_Module 
	@ln -s $(UPSTREAM_REF)/src_Core/ISA $(UPSTREAM_SRC)/ISA 
	@ln -s $(UPSTREAM_REF)/src_Core/Near_Mem_IO $(UPSTREAM_SRC)/Near_Mem_IO 
	@ln -s $(UPSTREAM_REF)/src_Core/Near_Mem_VM $(UPSTREAM_SRC)/Near_Mem_VM 
	@ln -s $(UPSTREAM_REF)/src_Core/PLIC $(UPSTREAM_SRC)/PLIC 
	@ln -s $(UPSTREAM_REF)/src_Core/RegFiles $(UPSTREAM_SRC)/RegFiles 
