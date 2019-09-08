#!/usr/bin/env python3
# autocore usage:
#
#  -h --help                         Print this message
#  -v --verbose
#  -q --quiet
#
#     Making a new configuration
#
#  -n --new     <conf_name>          Tells tool to make a new conf
#     --arch    <arch_str>           Basic risc-v string, ex: 'rv32imac'
#     --priv    <priv_str>           Priv levels to use,  ex: 'mu'
#     --fabric  [32|64]              Fabric definition
#     --tv-off  (default)
#     --tv-on                        Toggle for tandem verif
#     --db-off  (default)
#     --db-on                        Toggle for debug module
#     --mult    [serial|synth]       Multiplier choice, requires M extension
#                                    synth is default
#     --shift   [serial|barrel|mult] Shifter Choice, mult requires M
#                                    default barrel
#     --init-mem-zero                Initial memory zero option
#
#     Using an existing conf
#
#  -b --build   <conf_name>          Build the proc specified by the file in
#                                    the conf dir

import os, sys, argparse

#############################
##                         ##
## Command Line            ##
##                         ##
#############################

class parser_with_error(argparse.ArgumentParser):
  def error(self, msg = ""):
    if(msg): print("ERROR: %s" % msg)
    source = open(sys.argv[0]) # open the source for this script
    for(line_num, line) in enumerate(source):
      if(line[0] != "#"): sys.exit(msg != "")
      if(line_num > 1):   print(line[1:].rstrip("\n"))

def parse():
  parser = parser_with_error(add_help = False)

  # basic use args

  parser.add_argument("-h", "--help", action = "store_true")

  verbosity = parser.add_mutually_exclusive_group()

  verbosity.add_argument("-v", "--verbose", action = "store_true")
  verbosity.add_argument("-q", "--quiet", action = "store_true")

  # new or old conf

  mode = parser.add_mutually_exclusive_group()

  mode.add_agrument("-n", "--new", action = "store_true")
  mode.add_agrument("-b", "--build", action = "store_true")

