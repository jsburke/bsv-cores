#################################################
##                                             ##
##  Bluespec Processor Build Environment       ##
##                                             ##
#################################################

HERE   = $(patsubst %/,%,$(dir $(abspath $(MAKEFILE_LIST))))
SPACE :=
SPACE += 

#################################################
##                                             ##
##  Core Controls                              ##
##                                             ##
#################################################

XLEN       ?= 64

  # which core I want to build simulations or
  # verilog of.  May be mixed due to above
CORE       ?= Flute
ARCH        = -D RV$(XLEN)
FABRIC     ?= -D FABRIC64

  # default ISA extensions
  # TODO: D at least requires F, C may have
  #       dependencies.  how to enforce like below
ifeq ($(EXT),)
  EXT += -D ISA_I
  EXT += -D ISA_M
  EXT += -D ISA_A
  # EXT += -D ISA_F
  # EXT += -D ISA_D
  EXT += -D ISA_C
endif

  # TODO: general dependency order is S < U < M
  #       enforce this here some how
ifeq ($(PRIV),)
  PRIV += -D ISA_PRIV_M
  # PRIV += -D ISA_PRIV_S
  PRIV += -D ISA_PRIV_U
endif

NEAR_MEM ?= -D Near_Mem_Caches
# NEAR_MEM ?= -D Near_Mem_TCM

INSTANCE ?= $(shell echo $(CORE)$(ARCH) $(EXT) $(PRIV) | sed -e "s/-D//g" -e "s/ISA_/__/" -e "s/PRIV_/__/" -e "s/ //g" -e "s/ISA_//g" -e "s/PRIV_//g" -e "s/__/_/g")

CORE_DEFINES = $(ARCH) $(FABRIC) $(EXT) $(PRIV) $(NEAR_MEM)

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
BSV_INFO      = $(BSV_BUILD) 
BSV_SIM       = $(BSV_BUILD) 
BSV_VERILOG   = $(INST_DIR)/verilog

BSC_DIRS       = -bdir $(BSV_BUILD) -simdir $(BSV_SIM) -info-dir $(BSV_INFO) -vdir $(BSV_VERILOG)

BSC_OPTS       = -keep-fires -aggressive-conditions -no-warn-action-shadowing -no-show-timestamps -check-assert -show-range-conflict
BSC_DONT_WARN  = -suppress-warnings G0020
BSC_RTS        = +RTS -K128M -RTS

BSC_NON_CPU    = $(subst $(SPACE),:,$(addprefix $(UPSTREAM_SRC)/,$(filter-out Fabrics,$(filter-out CPU,$(patsubst $(UPSTREAM_SRC)/%/,%,$(wildcard $(UPSTREAM_SRC)/*/))))))

FABRICS_DIR  = $(UPSTREAM_SRC)/Fabrics/
BSC_FABRICS    = $(subst $(SPACE),:,$(addprefix $(FABRICS_DIR),$(filter-out README_Fabrics.txt,$(patsubst $(FABRICS_DIR)%,%,$(wildcard $(FABRICS_DIR)*/)))))

BSC_PATH       = -p $(UPSTREAM_SRC)/CPU/Common:$(UPSTREAM_SRC)/CPU/$(CORE):$(BSC_NON_CPU):$(BSC_FABRICS):+
BSV_TOP        = $(UPSTREAM_SRC)/Top/Top_HW_Side.bsv
BSIM_EXE       = $(INST_DIR)/bsim 

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

.PHONY: dummy
dummy:
	@echo "$(INST_DIR)"

.PHONY: submodules
submodules:
	@if git submodule status | egrep -q '^[-]|^[+]' ; then \
	    git submodule update --init --recursive; \
	fi

$(INST_DIR): submodules
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
bsim: $(BSIM_EXE)
$(BSIM_EXE): $(INST_DIR)
	bsc -u -elab -sim $(BSC_DIRS) $(CORE_DEFINES) $(BSC_OPTS) $(BSC_DONT_WARN) $(BSC_RTS) $(BSC_PATH) $(BSV_TOP)
	bsc -sim -parallel-sim-link 8 $(BSC_DIRS) -e mkTop_HW_Side -o $(BSIM_EXE) -Xc++  -D_GLIBCXX_USE_CXX11_ABI=0 -Xl -v -Xc -O3 -Xc++ -O3 $(UPSTREAM_SRC)/Top/C_Imported_Functions.c
