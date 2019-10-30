#!/usr/bin/env python3
#autocore usage:
#  -h --help                         Print this message
#
#  -v --verbose
#  -q --quiet                        (default)
#
#     Making and building configurations
#
#  -n --new      <conf_name>          Tells tool to make a new conf
#  -f --fast     <conf_name>          Combines both --new and --build in one step
#
#     --core     <core_str>           Which core to use (Piccolo, Flute) 
#     --arch     <arch_str>           Basic risc-v string, ex: 'rv32imac'
#     --priv     <priv_str>           Priv levels to use,  ex: 'mu'
#     --fabric   <32|64>              Fabric definition (default 64)
#     --near-mem <Caches|TCM>         Near Mem as Caches or Tightly coupled memory
#     --tv                            Enable tandem verif (default off)
#     --db                            Enable debug module (default off)
#     --mult     <serial|synth>       Multiplier choice, requires M extension
#                                     synth is default
#     --shift    <serial|barrel|mult> Shifter Choice, mult requires M
#                                     default barrel
#     --init-mem-zero                 Initial memory zero option (default off)
#     --target   <target_name>        specify a makefile target
#                                     [all (default), verilog, bsim, verilator]
#     --top-file <path/to/file>       Specifies a new top file for bsc
#                                     may cause simulation behavior to break
#     --bsc-path <list:of:paths>      new colon separated list of directories to
#                                     look into for building. (exclusive with --bsc-path-aid) 
#     --bsc-path-aid                  use a series of prompts to generate bsc path
#                                     rather than entering a giant string
#
#     Using an existing conf
#
#  -b --build   <conf_name>           Build the proc specified by the file in
#                                     the conf dir
#
#     --dry-run                       Uses the conf specified by --build to
#                                     launch a make dry run
#     --force-target <target_name>    Forces a specific makefile target
#                                     This overrides conf values set by --target

import os, sys, argparse

here =  os.path.abspath(os.path.dirname(sys.argv[0]))

# allowed choices for certain descriptors

cores       = ["Piccolo", "Flute"]
privs       = ["m", "mu", "msu"]
fabrics     = [32, 64]
multipliers = ["serial", "synth"]
shifters    = ["serial", "barrel", "mult"]
near_mems   = ["Caches", "TCM"]
targets     = ["all", "verilog", "bsim", "verilator"]

# configuration file controls

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

  # verbosity

  prog_verbose = parser.add_mutually_exclusive_group()

  prog_verbose.add_argument("-v", "--verbose", action = "store_const", dest = "verbosity", const = "v")
  prog_verbose.add_argument("-q", "--quiet", action = "store_const", dest = "verbosity", const = "q")
  parser.set_defaults(verbosity = "q")

  # sub args for --new

  parser.add_argument("--core", choices = cores, type = str)
  parser.add_argument("--arch", type = str)
  parser.add_argument("--priv", choices = privs, type = str)
  parser.add_argument("--fabric", choices = fabrics, type = int)
  parser.add_argument("--tv", action = "store_true")
  parser.add_argument("--db", action = "store_true")
  parser.add_argument("--init-mem-zero", action = "store_true")
  parser.add_argument("--mult", choices = multipliers, type = str)
  parser.add_argument("--shift", choices = shifters, type = str)
  parser.add_argument("--near-mem", choices = near_mems, type = str)
  parser.add_argument("--target", choices = targets, type = str)
  parser.add_argument("--top-file", type = str)
  parser.add_argument("--bsc-path", type = str)
  parser.add_argument("--bsc-path-aid", action = "store_true")

  # sub args for --build

  parser.add_argument("--dry-run", action = "store_true")#, dest = "dry_run")
  parser.add_argument("--force-target", type = str)#, dest = "force_target")

  options     = parser.parse_args()

  if options.help:
    parser.error()
  else:
    return args_status_get(options, sys.argv) # list of (argparse-dest, T/F cli use, value given)

def args_status_get(args, argv):
  args_tuples = []
  for arg in vars(args):
    arg_value = getattr(args, arg)
    arg_tuple = (arg, arg_value)
    
    is_arg_used = True if (("--" + arg.replace("_","-") in argv) or (arg_value not in [None, False])) else False
    if is_arg_used:
      args_tuples.append(arg_tuple)
  return args_tuples

#############################
##                         ##
## Support Functions       ##
##                         ##
#############################

  # function to gather bitness and risc-v extensions desired
  # input is in the form of something like 'rv32imac'
def rv_arch_parse(rv_str):
  xlen = rv_str[:4]
  ext  = rv_str[4:].replace("g","imafd")

  if not("i" in ext):  # I extenstion is mandatory
    print("ERROR: RV I extension is mandatory\n")
    sys.exit()

  if (("d" in ext) and not("f" in ext)):
    print("ERROR: RV D requires RV F\n")
    sys.exit()

  if not((xlen == "rv32") or (xlen == "rv64")):
    print("ERROR: arch must be rv32 or rv64\n")
    sys.exit()

  return [xlen, ext]

  # function that will write a new config file
  # based on the cli args.  
def new_conf_build(options, path, conf_name):
  core        = options.core
  [xlen, ext] = rv_arch_parse(options.arch.lower())
  privs       = options.priv
  fabric      = 64 if not options.fabric else options.fabric
  tv          = "on" if options.tv       else "off"
  db          = "on" if options.db       else "off"
  init_mem_zero    = "on" if options.init_mem_zero else "off"
  multiply    = options.mult
  shifter     = options.shift
  near_mem    = options.near_mem
  target      = options.target
  top_file    = options.top_file
  bsc_path    = options.bsc_path

  if not core:
    print("Error: a core must be specified with --core")
    sys.exit()

  if not privs:
    print("Error: a privilidge scheme must be defined with --priv")
    sys.exit()

  new_conf = conf_filename_make(path, conf_name)

  fp = open(new_conf, "w+")

  fp.write("core%s%s\n"     % (conf_delimiter, core))
  fp.write("arch%s%s\n"     % (conf_delimiter, xlen))
  fp.write("ext%s%s\n"      % (conf_delimiter, ext))
  fp.write("priv%s%s\n"     % (conf_delimiter, privs))
  fp.write("fabric%s%d\n"   % (conf_delimiter, fabric))
  fp.write("mult%s%s\n"     % (conf_delimiter, multiply))
  fp.write("shift%s%s\n"    % (conf_delimiter, shifter))
  fp.write("tv%s%s\n"       % (conf_delimiter, tv))
  fp.write("db%s%s\n"       % (conf_delimiter, db))
  fp.write("init_mem_zero%s%s\n" % (conf_delimiter, init_mem_zero))
  fp.write("target%s%s\n"   % (conf_delimiter, target))
  fp.write("top_file%s%s\n" % (conf_delimiter, top_file))
  fp.write("bsc_path%s%s\n" % (conf_delimiter, bsc_path))

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

  if key == 'ext':
    make_line += 'EXT="'
    for letter in value:
      if letter not in 'imafdc':
        print('Error: %s not a valid extension, should be from imafdc\n' % letter)
        sys.exit()
      else:
        make_line += '-D ISA_' + letter.upper() + ' '
    make_line += '"'
  elif key == 'priv':
    make_line += 'PRIV="'
    for letter in value:
      if letter not in 'msu':
        print('Error: %s not a valid priv, should be from msu\n' % letter)
        sys.exit()
      else:
        make_line += '-D ISA_PRIV_' + letter.upper() + ' '
    make_line += '"'
  elif key == 'fabric':
    if value in ['32', '64']:
      make_line += 'FABRIC="-D FABRIC' + value + '"'
    else:
      print('Error: %s not a valid fabric size, should be 32 or 64\n' % value)
      sys.exit()
  elif key == 'arch':
    if value in ['rv32', 'rv64']:
      make_line += 'ARCH="-D ' + value.upper() + '"'
    else:
      print('Error: %s not a valid architecture, should be rv32 or rv64\n' % value)
      sys.exit()
  elif key == 'core':
    if value not in cores:
      print('Error: %s not a valid core, should be Piccolo or Flute\n' % value)
      sys.exit()
    else:
      make_line += 'CORE="' + value + '"'
  elif key == 'mult':
    if value not in multipliers: 
      print('Error: %s not a valid multiplier, should be synth or serial\n' % value)
      sys.exit()
    else:
      make_line += 'MUL="-D ' + value.upper() + '"'
  elif key == 'shift':
    if value not in shifters: 
      print('Error: %s not a valid multiplier, should be synth ,serial, or barrel\n' % value)
      sys.exit()
    else:
      make_line += 'SHIFT="-D ' + value.upper() + '"'
  elif key == 'near_mem':
    if value not in near_mems:
      print('Error: %s not a valid near mem, should be Caches or TCM\n' % value)
      sys.exit()
    else:
      make_line += 'NEAR_MEM="-D Near_Mem_' + value + '"'
  elif key == 'tv':
    if value not in ['on', 'off']:
      print('Error: %s not valid for tandem verif, should be on or off\n' % value)
      sys.exit()
    else:
      prefix = 'INCLUDE' if value is 'on' else 'EXCLUDE'
      make_line += 'TV="-D ' + prefix + '_TANDEM_VERIF"'
  elif key == 'db':
    if value not in ['on', 'off']:
      print('Error: %s not valid for debug, should be on or off\n' % value)
      sys.exit()
    else:
      prefix = 'INCLUDE' if value is 'on' else 'EXCLUDE'
      make_line += 'DEBUG="-D ' + prefix + '_GDB_CONTROL"'
  elif key == 'init_mem_zero':
    if value not in ['on', 'off']:
      print('Error: %s not valid for initializing memory, should be on or off\n' % value)
      sys.exit()
    else:
      prefix = 'INCLUDE' if value is 'on' else 'EXCLUDE'
      make_line += 'MEM_ZERO="-D ' + prefix + '_INITIAL_MEMZERO"'
  elif key == 'target':
    if not ignore_target:
      if value not in targets:
        print('Error: %s is not a valid make target, should be all, verilog, verilator, or bsim\n' % value)
        sys.exit()
      else:
        make_line += " " + value
  elif key == 'top_file':
    if value != "None":
      make_line += 'BSV_TOP="' + value +'"'
  elif key == 'bsc_path':
    make_line += 'BSC_PATH="-p ' + value + '"'
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

  for option in options:
    print(option)

  sys.exit()

  conf_name = next(fn for fn in [options.new, options.build, options.fast] if fn is not None)

  # make a new configuration of a core
  if (options.new or options.fast):
    new_conf_build(options, here, conf_name)

  # make the verilog and sims defined in a configuration
  if (options.build or options.fast):
    build_conf = conf_filename_make(here, conf_name)
    conf_make(build_conf, options.dry_run, options.force_target)

main()
