#
# @MIPS CPU TESTBENCH
# @brief:  TESTBENCH FOR MIPS CPU
# @version 0.1
# @date 2021-11-22
#
# @copyright Copyright (c) 2021
#
#
#!/bin/bash
#set -eou pipefail
#$1 is absolute or relative

#echo $1
#echo $2 which is the instruction to be tested

#$1 is the location of a cpu.v
#we must recompile for every instruction (iterate through)
#we must rename the RAM output txt parameter for each instruction.

#list of instructions?
#problem is the compilation - $1 is the directory i.e. rtl, not the .v file







iverilog -Wall -g 2012 -s tb -o test/tb \
test/tb.v ${1}/*.v  #> /dev/null 2>&1 #change mips_avlong to *.v


./test/tb



#./cleardecals.sh