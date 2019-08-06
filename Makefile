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

  # where to base most symlinks and most of the 
  # build from.
REF_CORE   ?= Flute

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
UPSTREAM_REF = $(UPSTREAM)/$(REF_CORE)

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

$(UPSTREAM_SRC):
	@mkdir -p $(UPSTREAM_SRC)

$(INST_DIR):
	@mkdir -p $(BSV_BUILD) $(BSV_VERILOG) $(BSV_INFO) $(BSV_SIM) $(VERILATOR_OBJ)

.PHONY: symlinks
symlinks: submodules $(UPSTREAM_SRC)
	@ln -s $(UPSTREAM_REF)/src_Core/BSV_Additional_Libs      $(UPSTREAM_SRC)/BSV_Additional_Libs
	@ln -s $(UPSTREAM_REF)/src_Core/Core                     $(UPSTREAM_SRC)/Core
	@ln -s $(UPSTREAM_REF)/src_Core/Debug_Module             $(UPSTREAM_SRC)/Debug_Module 
	@ln -s $(UPSTREAM_REF)/src_Core/ISA                      $(UPSTREAM_SRC)/ISA 
	@ln -s $(UPSTREAM_REF)/src_Core/Near_Mem_IO              $(UPSTREAM_SRC)/Near_Mem_IO 
	@ln -s $(UPSTREAM_REF)/src_Core/Near_Mem_VM              $(UPSTREAM_SRC)/Near_Mem_VM 
	@ln -s $(UPSTREAM_REF)/src_Core/PLIC                     $(UPSTREAM_SRC)/PLIC 
	@ln -s $(UPSTREAM_REF)/src_Core/RegFiles                 $(UPSTREAM_SRC)/RegFiles
	@ln -s $(UPSTREAM_REF)/src_Testbench/SoC                 $(UPSTREAM_SRC)/SoC
	@ln -s $(UPSTREAM_REF)/src_Testbench/Top                 $(UPSTREAM_SRC)/Top
	@ln -s $(UPSTREAM_REF)/src_Testbench/Fabrics             $(UPSTREAM_SRC)/Fabrics
	@mkdir -p $(UPSTREAM_SRC)/CPU/{Piccolo,Flute,Common}
	@ln -s $(UPSTREAM_REF)/src_Core/CPU/CPU_Decode_C.bsv     $(UPSTREAM_SRC)/CPU/Common/CPU_Decode_C.bsv
	@ln -s $(UPSTREAM_REF)/src_Core/CPU/CPU_Fetch_C.bsv      $(UPSTREAM_SRC)/CPU/Common/CPU_Fetch_C.bsv
	@ln -s $(UPSTREAM_REF)/src_Core/CPU/CPU_IFC.bsv          $(UPSTREAM_SRC)/CPU/Common/CPU_IFC.bsv
	@ln -s $(UPSTREAM_REF)/src_Core/CPU/CPU_Stage3.bsv       $(UPSTREAM_SRC)/CPU/Common/CPU_Stage3.bsv
	@ln -s $(UPSTREAM_REF)/src_Core/CPU/EX_ALU_functions.bsv $(UPSTREAM_SRC)/CPU/Common/EX_ALU_functions.bsv
	@ln -s $(UPSTREAM_REF)/src_Core/CPU/FPU.bsv              $(UPSTREAM_SRC)/CPU/Common/FPU.bsv
	@ln -s $(UPSTREAM_REF)/src_Core/CPU/FBox_Top.bsv         $(UPSTREAM_SRC)/CPU/Common/FBox_Top.bsv
	@ln -s $(UPSTREAM_REF)/src_Core/CPU/FBox_Core.bsv        $(UPSTREAM_SRC)/CPU/Common/FBox_Core.bsv
	@ln -s $(UPSTREAM_REF)/src_Core/CPU/IntMulDiv.bsv        $(UPSTREAM_SRC)/CPU/Common/IntMulDiv.bsv
	@ln -s $(UPSTREAM_REF)/src_Core/CPU/RISCV_MBox.bsv       $(UPSTREAM_SRC)/CPU/Common/RISCV_MBox.bsv
	@ln -s $(UPSTREAM_REF)/src_Core/CPU/Shifter_Box.bsv      $(UPSTREAM_SRC)/CPU/Common/Shifter_Box.bsv
	@ln -s $(FLUTE_DIR)/src_Core/CPU/Branch_Predictor.bsv    $(UPSTREAM_SRC)/CPU/Flute/Branch_Predictor.bsv
	@ln -s $(FLUTE_DIR)/src_Core/CPU/CPU_StageF.bsv          $(UPSTREAM_SRC)/CPU/Flute/CPU_StageF.bsv
	@ln -s $(FLUTE_DIR)/src_Core/CPU/CPU_StageD.bsv          $(UPSTREAM_SRC)/CPU/Flute/CPU_StageD.bsv
	@ln -s $(FLUTE_DIR)/src_Core/CPU/CPU_Stage1.bsv          $(UPSTREAM_SRC)/CPU/Flute/CPU_Stage1.bsv
	@ln -s $(FLUTE_DIR)/src_Core/CPU/CPU_Stage2.bsv          $(UPSTREAM_SRC)/CPU/Flute/CPU_Stage2.bsv
	@ln -s $(FLUTE_DIR)/src_Core/CPU/CPU_Globals.bsv         $(UPSTREAM_SRC)/CPU/Flute/CPU_Globals.bsv
	@ln -s $(FLUTE_DIR)/src_Core/CPU/CPU.bsv                 $(UPSTREAM_SRC)/CPU/Flute/CPU.bsv
	@ln -s $(PICCOLO_DIR)/src_Core/CPU/CPU_Stage1.bsv        $(UPSTREAM_SRC)/CPU/Piccolo/CPU_Stage1.bsv
	@ln -s $(PICCOLO_DIR)/src_Core/CPU/CPU_Stage2.bsv        $(UPSTREAM_SRC)/CPU/Piccolo/CPU_Stage2.bsv
	@ln -s $(PICCOLO_DIR)/src_Core/CPU/CPU_Globals.bsv       $(UPSTREAM_SRC)/CPU/Piccolo/CPU_Globals.bsv
	@ln -s $(PICCOLO_DIR)/src_Core/CPU/CPU.bsv               $(UPSTREAM_SRC)/CPU/Piccolo/CPU.bsv

.PHONY: clean
clean:
	@rm -rf $(UPSTREAM_SRC) $(BUILD_DIR)

#################################################
##                                             ##
##  Compile and Sim Targets                    ##
##                                             ##
#################################################

.PHONY: bsim
bsim: symlinks $(INST_DIR)
	@echo "nothing to do"
