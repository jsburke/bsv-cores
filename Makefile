#################################################
##                                             ##
##  Bluespec Processor Build Environment       ##
##                                             ##
#################################################

SPACE :=
SPACE += 

ifeq ($(OS),Linux)
  NPROC:=$(shell grep -c ^processor /proc/cpuinfo)
endif
ifeq ($(OS),Darwin)
  NPROC:=$(shell system_profiler | awk '/Number Of CPUs/{print $4}{next;}')
endif

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

ifneq (,$(findstring RV32,$(ARCH)))
  VIRT_MEM_SYS = -D Sv32
endif
ifneq (,$(findstring RV64,$(ARCH)))
  VIRT_MEM_SYS = -D SV39
endif

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

SHIFT ?= -D SHIFT_BARREL
# SHIFT ?= -D SHIFT_SERIAL
# SHIFT ?= -D SHIFT_MULT 

NEAR_MEM ?= -D Near_Mem_Caches
# NEAR_MEM ?= -D Near_Mem_TCM

TV       ?= -D INCLUDE_TANDEM_VERIF
DEBUG    ?= -D INCLUDE_GDB_CONTROL
MEM_ZERO ?= -D EXCLUDE_INITIAL_MEMZERO
# MEM_ZERO ?= -D INCLUDE_INITIAL_MEMZERO

ifeq ($(INSTANCE),)
  INSTANCE := $(shell echo $(CORE)$(ARCH) $(EXT) $(PRIV) | sed -e "s/-D//g" -e "s/ISA_/__/" -e "s/PRIV_/__/" -e "s/ //g" -e "s/ISA_//g" -e "s/PRIV_//g" -e "s/__/_/g")
endif

CORE_DEFINES = $(ARCH) $(FABRIC) $(EXT) $(PRIV) $(NEAR_MEM) $(TV) $(DEBUG) $(MEM_ZERO) $(VIRT_MEM_SYS)

#################################################
##                                             ##
##  Directories of Interest                    ##
##                                             ##
#################################################

SRC          = ./src
FLUTE_DIR    = $(SRC)/Flute
PICCOLO_DIR  = $(SRC)/Piccolo

BUILD_DIR    = ./build
INST_DIR     = $(BUILD_DIR)/$(INSTANCE)

#################################################
##                                             ##
##  Bluespec Build Controls                    ##
##                                             ##
#################################################

BSV_BUILD      = $(INST_DIR)/build
BSV_INFO       = $(BSV_BUILD) 
BSV_SIM        = $(BSV_BUILD) 
BSV_VERILOG    = $(INST_DIR)/verilog

BSC_DIRS       = -bdir $(BSV_BUILD) -simdir $(BSV_SIM) -info-dir $(BSV_INFO) -vdir $(BSV_VERILOG)

BSC_OPTS       = -keep-fires -aggressive-conditions -no-warn-action-shadowing -no-show-timestamps -check-assert -show-range-conflict
BSC_DONT_WARN  = -suppress-warnings G0020
BSC_RTS        = +RTS -K128M -RTS

BSC_PATH      ?= -p $(SRC)/CPU/Common:$(SRC)/CPU/$(CORE):$(SRC)/BSV_Additional_Libs:$(SRC)/Core:$(SRC)/Debug_Module:$(SRC)/ISA:$(SRC)/Near_Mem_IO:$(SRC)/Near_Mem_VM:$(SRC)/PLIC:$(SRC)/RegFiles:$(SRC)/SoC:$(SRC)/Top:$(SRC)/Fabrics/Adapters:$(SRC)/Fabrics/AXI4:$(SRC)/Fabrics/AXI4_Lite:+

TOP_FILE       ?= $(SRC)/Top/Top_HW_Side.bsv
BSIM_EXE       = $(INST_DIR)/bsim 

#################################################
##                                             ##
##  Verilator Compile Controls                 ##
##                                             ##
#################################################

VERILATOR_RSC = $(SRC)/Verilator
VERILATOR_OBJ = $(INST_DIR)/obj_dir
VSIM_EXE      = $(INST_DIR)/vsim

#################################################
##                                             ##
##  Iverilog Compile Controls                  ##
##                                             ##
#################################################

IVSIM_EXE     = $(INST_DIR)/ivsim

#################################################
##                                             ##
##  Software Build Controls                    ##
##                                             ##
#################################################

SW            = ./sw
RV_TESTS      = $(SW)/riscv-tests
ISA_TESTS     = $(RV_TESTS)/isa
BENCHMARKS    = $(RV_TESTS)/benchmarks

TOOLS         = ./tools
TOOLS_BUILD   = $(TOOLS)/build

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

$(TOOLS_BUILD):
	@mkdir -p $(TOOLS_BUILD)

.PHONY: tests
tests: submodules
	$(MAKE) -C $(ISA_TESTS)  -j$(NPROC)
	$(MAKE) -C $(BENCHMARKS) -j$(NPROC)

$(TOOLS_BUILD)/elf_to_hex: $(TOOLS_BUILD)
	cd $(TOOLS)/elf_to_hex && make
	mv $(TOOLS)/elf_to_hex/elf_to_hex $(TOOLS_BUILD)

.PHONY: clean
clean:
	@rm -rf $(BUILD_DIR) $(TOOLS_BUILD)

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
	bsc -u -elab -$* $(BSC_DIRS) $(CORE_DEFINES) $(BSC_OPTS) $(BSC_DONT_WARN) $(BSC_RTS) $(BSC_PATH) $(TOP_FILE)

.PHONY: bsim
bsim: $(BSIM_EXE)
$(BSIM_EXE): compile-sim
	bsc -sim -parallel-sim-link 8 $(BSC_DIRS) -e mkTop_HW_Side -o $(BSIM_EXE) -Xc++  -D_GLIBCXX_USE_CXX11_ABI=0 -Xl -v -Xc -O3 -Xc++ -O3 $(SRC)/Top/C_Imported_Functions.c

.PHONY: verilog
verilog: compile-verilog

.PHONY: verilator
verilator: $(VSIM_EXE)
$(VSIM_EXE): compile-verilog
	sed -f $(VERILATOR_RSC)/sed_script.txt $(BSV_VERILOG)/mkTop_HW_Side.v > tmp.v
	cat $(VERILATOR_RSC)/verilator_config.vlt $(VERILATOR_RSC)/import_DPI_C_decls.v tmp.v > $(BSV_VERILOG)/mkTop_HW_Side_edited.v
	rm -f tmp.v
	cd $(INST_DIR) && verilator -I./verilog -I../../src/Lib_Verilog --stats -O3 -CFLAGS -O3 -LDFLAGS -static --x-assign fast --x-initial fast --noassert --cc ./verilog/mkTop_HW_Side_edited.v --exe sim_main.cpp ../../src/Top/C_Imported_Functions.c
	cp $(SRC)/Verilator/sim_main.cpp $(VERILATOR_OBJ)/sim_main.cpp
	cd $(VERILATOR_OBJ) && make -j -f VmkTop_HW_Side_edited.mk VmkTop_HW_Side_edited
	cp $(VERILATOR_OBJ)/VmkTop_HW_Side_edited $(VSIM_EXE)

.PHONY: iverilog
iverilog: $(IVSIM_EXE)
$(IVSIM_EXE): compile-verilog
	iverilog -o $(IVSIM_EXE) -y $(BSV_VERILOG) -y src/Lib_Verilog -DTOP=mkTop_HW_Side src/Lib_Verilog/main.v

.PHONY: sims
sims: bsim verilator iverilog

.PHONY: rebuild
rebuild: clean all
