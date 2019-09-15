#!/usr/bin/env python3
# autocore usage:
#
#  -h --help                         Print this message
#
#  -v --verbose
#  -q --quiet
#
#     Making a new configuration
#
#  -n --new     <conf_name>          Tells tool to make a new conf
#     --core    <core_str>           Which core to use (Piccolo, Flute) 
#     --arch    <arch_str>           Basic risc-v string, ex: 'rv32imac'
#     --priv    <priv_str>           Priv levels to use,  ex: 'mu'
#     --fabric  [32|64]              Fabric definition
#     --tv                           Enable tandem verif
#     --db                           Enable debug module
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

# allowed choices for certain descriptors

cores       = ["Piccolo", "Flute"]
fabrics     = [32, 64]
multipliers = ["serial", "synth"]
shifters    = ["serial", "barrel", "mult"]

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
      if(line[0] != "#"): sys.exit(msg != "") # exit program
      if(line_num > 1):   print(line[1:].rstrip("\n"))

def parse():
  parser = parser_with_error(add_help = False)

  # basic use args

  parser.add_argument("-h", "--help", action = "store_true")

  verbosity = parser.add_mutually_exclusive_group()

  verbosity.add_argument("-v", "--verbose", action = "store_true")
  verbosity.add_argument("-q", "--quiet", action = "store_true")

  # new or old conf

  mode = parser.add_mutually_exclusive_group(required = True)

  mode.add_argument("-n", "--new",   type = str)
  mode.add_argument("-b", "--build", type = str)

  # sub args for --new

  parser.add_argument("--core", choices = cores, type = str)
  parser.add_argument("--arch", type = str)
  parser.add_argument("--priv", type = str)
  parser.add_argument("--fabric", choices = fabrics, type = int)
  parser.add_argument("--tv", action = "store_true")
  parser.add_argument("--db", action = "store_true")
  parser.add_argument("--init-mem-zero", action = "store_true")
  parser.add_argument("--mult", choices = multipliers, type = str)
  parser.add_argument("--shift", choices = shifters, type = str)

  options     = parser.parse_args()
  descriptors = [options.core, options.arch, options.priv, options.fabric, options.tv, options.db, options.init_mem_zero, options.mult, options.shift]

  if options.help:
    parser.error()
  if (options.build and any(descriptors)):
    parser.error(msg = "Cannot use --build with core description options")
  else:
    return options

#############################
##                         ##
## Support Functions       ##
##                         ##
#############################

def conf_filename_make(conf_str)
  return conf_str + ".conf" 

def riscv_string_parse(rv_str):
  bitness    = int(rv_str[2:4])
  extensions = rv_str[4:].replace("g","imafd")
  return [bitness, extensions]

def riscv_priv_parse(rv_priv_str):
  priv_list = list(rv_priv_str)
  return False

def new_conf_build(options):

def conf_make(filename):

#############################
##                         ##
## Main Script             ##
##                         ##
#############################

def main():
  options = parse()

  if options.new:
    new_conf_build(options)

  if options.build:
    build_conf = conf_filename_make(options.build)
    conf_make(build_conf)

main()
