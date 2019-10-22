#!/usr/bin/env python3
# autocore usage:
#
#  -h --help                         Print this message
#
#  -v --verbose
#  -q --quiet                        (default)
#
#     Making and building configurations
#
#  -n --new     <conf_name>          Tells tool to make a new conf
#  -f --fast    <conf_name>          Combines both --new and --build in one step
#
#     --core    <core_str>           Which core to use (Piccolo, Flute) 
#     --arch    <arch_str>           Basic risc-v string, ex: 'rv32imac'
#     --priv    <priv_str>           Priv levels to use,  ex: 'mu'
#     --fabric  [32|64]              Fabric definition (default 64)
#     --tv                           Enable tandem verif (default off)
#     --db                           Enable debug module (default off)
#     --mult    [serial|synth]       Multiplier choice, requires M extension
#                                    synth is default
#     --shift   [serial|barrel|mult] Shifter Choice, mult requires M
#                                    default barrel
#     --init-mem-zero                Initial memory zero option (default off)
#
#     Using an existing conf
#
#  -b --build   <conf_name>          Build the proc specified by the file in
#                                    the conf dir

import os, sys, argparse

here =  os.path.abspath(os.path.dirname(sys.argv[0]))

# allowed choices for certain descriptors

cores       = ["Piccolo", "Flute"]
privs       = ["m", "mu", "msu"]
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
  parser.add_argument("--init-mem-zero", action = "store_true", dest = "mem_zero")
  parser.add_argument("--mult", choices = multipliers, type = str)
  parser.add_argument("--shift", choices = shifters, type = str)
  parser.set_defaults(mult  = "synth")
  parser.set_defaults(shift = "barrel")

  options     = parser.parse_args()
  descriptors = [options.core, options.arch, options.priv, options.fabric, options.tv, options.db, options.mem_zero, options.mult, options.shift]

  if options.help:
    parser.error()
  else:
    return options

#############################
##                         ##
## Support Functions       ##
##                         ##
#############################

def rv_arch_parse(rv_str):
  xlen = rv_str[:4]
  ext  = rv_str[4:].replace("g","imafd")

  if not("i" in ext):
    print("ERROR: RV I extension is mandatory\n")
    sys.exit()

  if (("d" in ext) and not("f" in ext)):
    print("ERROR: RV D requires RV F\n")
    sys.exit()

  if not((xlen == "rv32") or (xlen == "rv64")):
    print("ERROR: arch must be rv32 or rv64\n")
    sys.exit()

  return [xlen, ext]

def new_conf_build(options, path, conf_name):
  core        = options.core
  [xlen, ext] = rv_arch_parse(options.arch.lower())
  privs       = options.priv
  fabric      = 64 if not options.fabric else options.fabric
  tv          = "on" if options.tv       else "off"
  db          = "on" if options.db       else "off"
  mem_zero    = "on" if options.mem_zero else "off"
  multiply    = options.mult
  shifter     = options.shift

  if not core:
    print("Error: a core must be specified with --core")
    sys.exit()

  if not privs:
    print("Error: a privilidge scheme must be defined with --priv")
    sys.exit()

  new_conf = conf_filename_make(path, conf_name)

  fp = open(new_conf, "w+")

  fp.write("core:%s\n"   % core)
  fp.write("arch:%s\n"   % xlen)
  fp.write("ext:%s\n"    % ext)
  fp.write("priv:%s\n"   % privs)
  fp.write("fabric:%d\n" % fabric)
  fp.write("mult:%s\n"   % multiply)
  fp.write("shift:%s\n"  % shifter)
  fp.write("tv:%s\n"     % tv)
  fp.write("db:%s\n"     % db)
  fp.write("mem_zero:%s" % mem_zero)

  fp.close()

def conf_filename_make(path, conf_str):
  if conf_str.endswith(".conf"):
    conf_file = path + "/conf/" + conf_str
  else:
    conf_file = path + "/conf/" + conf_str + ".conf"
  return conf_file

def conf_line_parse(line):
  [key, value] = line.rstrip().split(":")
  make_line = " "

  if key == "ext":
    make_line += "EXT = "
    for letter in value:
      if letter not in "imafdc":
        print("Error: %s not a valid extension, should be from imafdc\n" % letter)
        sys.exit()
      else:
        make_line += " -D ISA_" + letter.upper()
  elif key == "priv":
    make_line += "PRIV = "
    for letter in value:
      if letter not in "msu":
        print("Error: %s not a valid priv, should be from msu\n" % letter)
        sys.exit()
      else:
        make_line += " -D ISA_PRIV_" + letter.upper()
  elif key == "fabric":
    if (value is "32") or (value is 64):
      make_line += "FABRIC = -D FABRIC" + value
    else:
      print("Error: %s not a valid fabric size, should be 32 or 64\n" % letter)
      sys.exit()
  elif key == "arch":
    if value in ["rv32", "rv64"]:
      make_line += "ARCH = -D " + value.upper()
    else:
      print("Error: %s not a valid architecture, should be rv32 or rv64\n" % value)
      sys.exit()
  elif key == "core":
    if value not in cores:
      print("Error: %s not a valid core, should be Piccolo or Flute\n" % value)
      sys.exit()
    else:
      make_line += "CORE = -D " + value
  elif key == "mult":
    if value not in multipliers: 
      print("Error: %s not a valid multiplier, should be synth or serial\n" % value)
      sys.exit()
    else:
      make_line += "MUL = -D " + value.upper()
  elif key == "shift":
    if value not in shifters: 
      print("Error: %s not a valid multiplier, should be synth ,serial, or barrel\n" % value)
      sys.exit()
    else:
      make_line += "SHIFT = -D " + value.upper()
  elif key == "near_mem":
    if value not in near_mem:
      print("Error: %s not a valid near mem, should be caches or tcm\n" % value)
      sys.exit()
    else:
      make_line += "NEAR_MEM = -D Near_Mem_" + value
  elif key == "tv":
    if not ((value is "on") or (value is "off")):
      print("Error: %s not valid for tandem verif, should be on or off\n" % value)
      sys.exit()
    else:
      prefix = "INCLUDE" if value is "on" else "EXCLUDE"
      make_line += "TV = -D " + prefix + "_TANDEM_VERIF"
  elif key == "db":
    if not ((value is "on") or (value is "off")):
      print("Error: %s not valid for debug, should be on or off\n" % value)
      sys.exit()
    else:
      prefix = "INCLUDE" if value is "on" else "EXCLUDE"
      make_line += "DEBUG = -D " + prefix + "_GDB_CONTROL"
  elif key == "mem_zero":
    if not ((value is "on") or (value is "off")):
      print("Error: %s not valid for initializing memory, should be on or off\n" % value)
      sys.exit()
    else:
      prefix = "INCLUDE" if value is "on" else "EXCLUDE"
      make_line += "TV = -D " + prefix + "_INITIAL_MEMZERO"
  else:
    print("Error: key %s not recognized" % key)
    sys.exit()

  return make_line

def conf_make(filename):
  instance = os.path.basename(filename).split(".")[0]

  make_command = 'make all INSTANCE="' + instance + '" '

  with open(filename, "r") as conf:
    for line in conf:
      make_append = conf_line_parse(line)
      print("%s\n" % make_append)

      #if (make_append == "error"):
      #  print("Error: some line in %.conf is bad\n" % instance)
      #  sys.exit()
      #else:
      #  make_command += make_append

  ## issue make command via sys or something

#############################
##                         ##
## Main Script             ##
##                         ##
#############################

def main():
  options = parse()

  conf_name = next(fn for fn in [options.new, options.build, options.fast] if fn is not None)

  if (options.new or options.fast):
    new_conf_build(options, here, conf_name)

  if (options.build or options.fast):
    build_conf = conf_filename_make(here, conf_name)
    conf_make(build_conf)

#############################
##                         ##
## Go Button               ##
##                         ##
#############################

main()
