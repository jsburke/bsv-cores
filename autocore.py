#!/usr/bin/env python3
#autocore usage:
#  -h  --help                         Print this message
#
# Making and building configurations
#
#  -n  --new      <conf_name>          Tells tool to make a new conf
#  -f  --fast     <conf_name>          Combines both --new and --build in one step
#
#      --core     <core_str>           Which core to use (Piccolo, Flute) 
#      --arch     <arch_str>           Basic risc-v string, ex: 'rv32imac'
#      --priv     <priv_str>           Priv levels to use,  ex: 'mu'
#      --fabric   <32|64>              Fabric definition (default 64)
#      --near-mem <Caches|TCM>         Near Mem as Caches or Tightly coupled memory
#      --tv                            Enable tandem verif (default off)
#      --db                            Enable debug module (default off)
#      --mult     <serial|synth>       Multiplier choice, requires M extension
#                                      synth is default
#      --shift    <serial|barrel|mult> Shifter Choice, mult requires M
#                                      default barrel
#      --init-mem-zero                 Initial memory zero option (default off)
#      --target   <target_name>        specify a makefile target
#                                      [all (default), verilog, bsim, verilator, iverilog]
#      --top-file <path/to/file>       Specifies a new top file for bsc
#                                      may cause simulation behavior to break
#      --bsc-path <list:of:paths>      new colon separated list of directories to
#                                      look into for building
#
#      Using an existing conf
#
#  -b  --build   <conf_name>           Build the proc specified by the file in
#                                      the conf dir
#
#      --dry-run                       Uses the conf specified by --build to
#                                      launch a make dry run
#      --force-target <target_name>    Forces a specific makefile target
#                                     This overrides conf values set by --target

import os, sys, argparse, subprocess

here =  os.path.abspath(os.path.dirname(sys.argv[0]))

# allowed choices for certain descriptors

cores       = ["Piccolo", "Flute"]
privs       = ["m", "mu", "msu"]
fabrics     = ["FABRIC32", "FABRIC64"]
multipliers = ["serial", "synth"]
shifters    = ["serial", "barrel", "mult"]
near_mems   = ["Caches", "TCM"]
targets     = ["all", "verilog", "bsim", "verilator", "iverilog"]

# script controls

conf_delimiter = "--"

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
      if(line_num > 0):   print(line[1:].rstrip("\n"))

def parse():
  parser = parser_with_error(add_help = False)

  # basic use args

  mode = parser.add_mutually_exclusive_group(required = True)

  mode.add_argument("-n", "--new",   type = str)
  mode.add_argument("-b", "--build", type = str)
  mode.add_argument("-f", "--fast",  type = str)
  mode.add_argument("-h", "--help", action = "store_true") # put help here to avoid dumb errors

  # sub args for --new

  parser.add_argument("--core", choices = cores, type = str)
  parser.add_argument("--arch", type = str)
  parser.add_argument("--priv", choices = privs, type = str)
  parser.add_argument("--fabric", choices = fabrics, type = str)
  parser.add_argument("--tv", action = "store_true")
  parser.add_argument("--db", action = "store_true")
  parser.add_argument("--init-mem-zero", action = "store_true")
  parser.add_argument("--mult", choices = multipliers, type = str)
  parser.add_argument("--shift", choices = shifters, type = str)
  parser.add_argument("--near-mem", choices = near_mems, type = str)
  parser.add_argument("--target", choices = targets, type = str)
  parser.add_argument("--top-file", type = str)
  parser.add_argument("--bsc-path", type = str)

  # sub args for --build

  parser.add_argument("--dry-run", action = "store_true")
  parser.add_argument("--force-target", choices = targets, type = str)

  options     = parser.parse_args()

  if options.help:
    parser.error()
  else:
    return args_status_get(options, sys.argv) # dict of (argparse-dest, value given)

def args_status_get(args, argv):
  args_dict = {}
  for arg in vars(args):
    arg_value = getattr(args, arg)
    arg_tuple = (arg, arg_value)
    
    is_arg_used = True if (("--" + arg.replace("_","-") in argv) or (arg_value not in [None, False])) else False
    if is_arg_used:
      args_dict.update({arg : arg_value})
  return args_dict

#############################
##                         ##
## Support Functions       ##
##                         ##
#############################

  # function that will write a new config file
  # based on the cli args.  
def new_conf_build(options, conf_file):
  fp = open(conf_file, "w+")
  
  for key, value in options.items():
    fp.write("%s%s%s\n" % (key, conf_delimiter, value))

  fp.close()

  # function to make sure the place we read or write
  # a conf from is where the project expects it
def conf_filename_make(path, conf_str):
  if conf_str.endswith(".conf"):
    conf_file = path + "/conf/" + conf_str
  else:
    conf_file = path + "/conf/" + conf_str + ".conf"
  return conf_file

  # function to read a conf file and transform it
  # into a string that make can consume on the command line
def conf_line_parse(line, ignore_target):
  [key, value] = line.rstrip().split(conf_delimiter)
  make_line = ' '

  ###################################
  ##                               ##
  ## Parse by key as needed        ##
  ##                               ##
  ###################################

  if (key == 'target'):
    if not ignore_target: # nest to avoid issues on else portion
      make_line += value

  # CORE FABRIC BSC_PATH and TOP_FILE
  elif key in ["core", "fabric", "top_file"]:
    make_line += key.upper() + '=-D" ' + value + '"'

  # BSC_PATH is a little different
  elif key == 'bsc_path':
    path_ender = ':+' if not value.endswith(':+') else ''
    make_line += 'BSC_PATH="-p ' + value + path_ender +'"'

  # ARCH and EXT
  elif key == 'arch':
    make_line += 'ARCH=-D" ' + value[:4].upper() + '" EXT="'

    exts = value[4:].replace('g','imafd').upper() 
    for ext in exts:
      make_line += ' -D ISA_' + ext

    make_line += '"'

  # PRIV
  elif key == "priv":
    make_line += 'PRIV=" '
    for priv in value:
      make_line += ' -D ISA_PRIV_' + priv.upper()
    make_line += '"'

  # MULT and SHIFT
  elif key in ["mult", "shift"]:
    make_line += key.upper() + '=-D" ' + key.upper() + '_' + value.upper() + '"'

  # NEAR MEM
  elif key == "near_mem":
    make_line += 'NEAR_MEM=-D" Near_Mem_' + value + '"'

  elif key == 'tv':
      prefix = "INCLUDE" if value == 'True' else "EXCLUDE"
      make_line += 'TV=-D" ' + prefix + '_TANDEM_VERIF"'

  elif key == 'db':
      prefix = "INCLUDE" if value == 'True' else "EXCLUDE"
      make_line += 'DEBUG=-D" ' + prefix + '_GDB_CONTROL"'

  elif key == 'init_mem_zero':
      prefix = "INCLUDE" if value == 'True' else "EXCLUDE"
      make_line += 'MEM_ZERO=-D" ' + prefix + '_INITIAL_MEMZERO"'

  else:
    print('Error: key %s not recognized' % key)
    sys.exit()

  return make_line

  # function opens a conf and looks to the command line
  # to launch make
def conf_make(filename, is_dry_run, target):
  instance = os.path.basename(filename).split(".")[0]

  has_forced_target = (target != "") and (target is not None)
  make_command = 'make INSTANCE="' + instance + '" '

  with open(filename, "r") as conf:
    for line in conf:
      make_command += conf_line_parse(line, has_forced_target)

  if has_forced_target:
    make_command += " " + target

  if is_dry_run:
    make_command += " -n"

  print(make_command)
  os.system(make_command)

#############################
##                         ##
## Main Script             ##
##                         ##
#############################

def main():
  options = parse()

  conf_name = next(fn for fn in [options.get("new"), options.get("build"), options.get("fast")] if fn is not None)

  # what mode does the script operate under
  # --help managed in parse()
  is_mode_new   = options.get("new") is not None
  is_mode_build = options.get("build") is not None
  is_mode_fast  = options.get("fast") is not None

  # remove mode from options so it doesn't
  # get written to conf
  if is_mode_new:
    del options["new"]
  if is_mode_build:
    del options["build"]
  if is_mode_fast:
    del options["fast"]

  conf_file = conf_filename_make(here, conf_name)

  # make a new configuration of a core
  if is_mode_new or is_mode_fast:
    new_conf_build(options, conf_file)

  # make the verilog and sims defined in a configuration
  if is_mode_build or is_mode_fast:
    conf_make(conf_file, options.get("dry_run"), options.get("force_target"))

main()
