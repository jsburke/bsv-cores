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

  # which core I want to build simulations or
  # verilog of.  May be mixed due to above
CORE       ?= Flute
ARCH       ?= -D RV64
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

ifneq (,$(findstring ISA_M,$(EXT))) # weird Make logic: if "ISA_M" in EXT, empty does not match
  MUL ?= -D MULT_SYNTH
  #MUL ?= -D MULT_SERIAL
endif

  # Shift Options
  #
  # Barrel Shifter -- default
  # Serial Shifter -- slow, small HW utilization
  # Mult   Shifter -- lverages DSPs
  #
  # Can also disable all shift options and shifts trap as illegal insn

SHIFT ?= -D SHIFT_BARREL
# SHIFT ?= -D SHIFT_SERIAL
# SHIFT ?= -D SHIFT_MULT 

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

BSC_PATH      ?= -p $(UPSTREAM_SRC)/CPU/Common:$(UPSTREAM_SRC)/CPU/$(CORE):$(BSC_NON_CPU):$(BSC_FABRICS):+
BSV_TOP       ?= $(UPSTREAM_SRC)/Top/Top_HW_Side.bsv
BSIM_EXE       = $(INST_DIR)/bsim 

#################################################
##                                             ##
##  Verilator Compile Controls                 ##
##                                             ##
#################################################

VERILATOR_RSC = $(UPSTREAM_SRC)/Verilator
VERILATOR_OBJ = $(INST_DIR)/obj_dir
VSIM_EXE      = $(INST_DIR)/verilator_sim

#################################################
##                                             ##
##  Utility Targets                            ##
##                                             ##
#################################################

.PHONY: default
default: all

.PHONY: all
all: sims

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

.PHONY: help
help:
	@echo "bsv-cores Makefile usage"
	@echo " "
	@echo " ***** Targets *****"
	@echo " "
	@echo "  all (default) -- compile a bluesim simulator for the defined arch"
	@echo " "
	@echo "  bsim ----------- compile a bluesim simulator for the defined arch"
	@echo " "
	@echo "  verilator ------ compile a verilator simulator for the defined arch"
	@echo " "
	@echo "  sims ----------- build all sims for defined arch (same as all now)"
	@echo " "
	@echo "  clean ---------- delete dirs with generated code or binaries"
	@echo " "
	@echo "  rebuild -------- alias for clean then all"
	@echo " "
	@echo "  help ----------- print this message"
	@echo " "
	@echo " ***** Knobs *****"
	@echo "  "
	@echo "  Many variables can be used to alter the result."
	@echo "  Most will be absorbed into a build script at some point"
	@echo "  Look into the guts of the make file for potentially easier control"
	@echo " "
	@echo "  ARCH -- RV32 or RV64 for bitness"
	@echo " "
	@echo "  CORE -- Piccolo or Flute"
	@echo " "
	@echo "  EXT  -- List of ISA extensions in the fashion of -D ISA_I -D ISA_M"
	@echo " "
	@echo "  PRIV -- List of priv levels to be included like -D ISA_PRIV_M -D ISA_PRIV_U"
	@echo " "
	@echo " And many others, look into the codebase and makefile"
#################################################
##                                             ##
##  Compile and Sim Targets                    ##
##                                             ##
#################################################

.PHONY: compile-%
compile-%: submodules $(INST_DIR)
	bsc -u -elab -$* $(BSC_DIRS) $(CORE_DEFINES) $(BSC_OPTS) $(BSC_DONT_WARN) $(BSC_RTS) $(BSC_PATH) $(BSV_TOP)

.PHONY: bsim
bsim: $(BSIM_EXE)
$(BSIM_EXE): compile-sim
	bsc -sim -parallel-sim-link 8 $(BSC_DIRS) -e mkTop_HW_Side -o $(BSIM_EXE) -Xc++  -D_GLIBCXX_USE_CXX11_ABI=0 -Xl -v -Xc -O3 -Xc++ -O3 $(UPSTREAM_SRC)/Top/C_Imported_Functions.c

.PHONY: verilator
verilator: $(VSIM_EXE)
$(VSIM_EXE): compile-verilog
	sed -f $(VERILATOR_RSC)/sed_script.txt $(BSV_VERILOG)/mkTop_HW_Side.v > tmp.v
	cat $(VERILATOR_RSC)/verilator_config.vlt $(VERILATOR_RSC)/import_DPI_C_decls.v tmp.v > $(BSV_VERILOG)/mkTop_HW_Side_edited.v
	rm -f tmp.v
	cd $(INST_DIR) && verilator -I$(BSV_VERILOG) -I$(UPSTREAM_SRC)/Lib_Verilog --stats -O3 -CFLAGS -O3 -LDFLAGS -static --x-assign fast --x-initial fast --noassert --cc $(BSV_VERILOG)/mkTop_HW_Side_edited.v --exe sim_main.cpp $(UPSTREAM_SRC)/Top/C_Imported_Functions.c
	cp $(UPSTREAM_SRC)/Verilator/sim_main.cpp $(VERILATOR_OBJ)/sim_main.cpp
	cd $(VERILATOR_OBJ) && make -j -f VmkTop_HW_Side_edited.mk VmkTop_HW_Side_edited && cp VmkTop_HW_Side_edited $(VSIM_EXE)

.PHONY: sims
sims: bsim verilator

.PHONY: rebuild
rebuild: clean all
