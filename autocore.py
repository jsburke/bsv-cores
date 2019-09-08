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
