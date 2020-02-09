# bsv-cores

Project that aims to make configuring, modifying, and leveraging BlueSpec's open source Piccolo and Flute RISC-V cores simple and easy.  Rebuilding anything here will require the bluespec compiler `bsc`, though pregenerated verilog is available in the submodules.  One goal of this repo is storing various ways of building these cores in small config files so that people don't have to muck in the Makefiles or bluespec source code.

## Use at a high level

The `Makefile` contains a default build in itself, an RV64 IMAC Flute with Machine and User modes enabled, a debug module, and Bluespec's Tandem Verification.  Using `make help` will give a good glance into the make file, what knobs can be turned, and targets that will be interesting.

`autocore.py` is a script that can by used for generating a configuration of Piccolo or Flute, building a particular configuration, or both at once.  `./autocore.py [-h|--help]` gives info on the options that can be set for making a new config or building it.

## Contents

- `Makefile`    : As noted above, this can be used to build the cores
- `autocore.py` : Noted above, used to make and build configs
- `./conf`      : where the configs are stored, comes with `example.conf`
- `./upstream`  : where the bluespec submodules and symlinks into them are set up.  Builds look here for bsv

## Dependencies

- [bsc](https://github.com/B-Lang-org/bsc) : The BlueSpec Verilog Compiler
- verilator
- iverilog
- gcc/g++
- Python 3  :  Modules used -- os, sys, argparse, and subprocess
- Make 

## Future Desires

The `BSC_PATH` and `TOP_FILE` variables in the `Makefile` can be reassigned from the command line.  The main idea being that modifications to what Piccolo or FLute sit in or using their components for other things is desirable.  Future configuration work should allow for these to be redirected
