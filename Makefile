#################################################
##                                             ##
##  Bluespec Processor Build Environment       ##
##                                             ##
#################################################

HERE = $(patsubst %/,%,$(dir $(abspath $(MAKEFILE_LIST))))

#################################################
##                                             ##
##  Core Controls                              ##
##                                             ##
#################################################

XLEN       ?= 64

  # which core I want to build simulations or
  # verilog of.  May be mixed due to above
CORE       ?= Flute
ARCH        = RV$(XLEN)
FABRIC     ?= FABRIC64

  # default ISA extensions
  # TODO: D at least requires F, C may have
  #       dependencies.  how to enforce like below
ifeq ($(EXT),)
  EXT += ISA_I
  EXT += ISA_M
  EXT += ISA_A
  # EXT += ISA_F
  # EXT += ISA_D
  EXT += ISA_C
endif

  # TODO: general dependency order is S < U < M
  #       enforce this here some how
ifeq ($(ISA_PRIV),)
  PRIV += ISA_PRIV_M
  # PRIV += ISA_PRIV_S
  PRIV += ISA_PRIV_U
endif

INSTANCE ?= $(shell echo $(CORE)$(ARCH) $(EXT) $(PRIV) | sed -e "s/ISA_/__/" -e "s/PRIV_/__/" -e "s/ //g" -e "s/ISA_//g" -e "s/PRIV_//g" -e "s/__/_/g")

#################################################
##                                             ##
##  Directories of Interest                    ##
##                                             ##
#################################################

UPSTREAM     = $(HERE)/upstream
UPSTREAM_SRC = $(UPSTREAM)/src
FLUTE_DIR    = $(UPSTREAM_SRC)/Flute
PICCOLO_DIR  = $(UPSTREAM_SRC)/Piccolo

BUILD_DIR    = $(HERE)/build
INST_DIR     = $(BUILD_DIR)/$(INSTANCE)

#################################################
##                                             ##
##  Bluespec Build Controls                    ##
##                                             ##
#################################################

BSV_BUILD     = $(INST_DIR)/build
BSV_VERILOG   = $(INST_DIR)/verilog
BSV_INFO      = $(INST_DIR)/info
BSV_SIM       = $(INST_DIR)/sim

#################################################
##                                             ##
##  Verilator Compile Controls                 ##
##                                             ##
#################################################

VERILATOR_OBJ = $(INST_DIR)/obj

#################################################
##                                             ##
##  Utility Targets                            ##
##                                             ##
#################################################

.PHONY: submodules
submodules:
	@if git submodule status | egrep -q '^[-]|^[+]' ; then \
	    git submodule update --init --recursive; \
	fi

$(INST_DIR):
	@mkdir -p $(BSV_BUILD) $(BSV_VERILOG) $(BSV_INFO) $(BSV_SIM) $(VERILATOR_OBJ)

.PHONY: clean
clean:
	@rm -rf $(BUILD_DIR)

#################################################
##                                             ##
##  Compile and Sim Targets                    ##
##                                             ##
#################################################

.PHONY: bsim
bsim: $(INST_DIR)
	@echo "nothing to do"
