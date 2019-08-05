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
FLUTE_DIR    = $(UPSTREAM_SRC)/Flute
PICCOLO_DIR  = $(UPSTREAM_SRC)/Piccolo
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

$(UPSTREAM_SRC):
	@mkdir -p $(UPSTREAM_SRC)

  # below still needs Piccolo and Flute Specific CPU symlinks
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

