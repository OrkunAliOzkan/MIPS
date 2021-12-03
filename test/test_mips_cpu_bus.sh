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
set -eou pipefail
#$1 is absolute or relative

#echo $1
#echo $2 which is the instruction to be tested

#$1 is the location of a cpu.v
#we must recompile for every instruction (iterate through)
#we must rename the RAM output txt parameter for each instruction.

#list of instructions?
#problem is the compilation - $1 is the directory i.e. rtl, not the .v file


if [ $# -eq 1 ]
then
    instruction="*"
elif [ $# -eq 2 ]
then
    instruction=$2
else
    echo too many/few arguments
    exit 1
fi



testcases=/testcases/${instruction}.txt



for test in testcases #directory containing all the RAM outputs so we can compare against. iterate since it could be one, or all
    do
    test=$(basename ${test} .txt)
    #ram_file = 

    iverilog -Wall -g 2012 -s tb -o tb \
    -P tb.RAM_FILE = \"${test}.txt\" \
    -P tb.OUT_FILE = \"${test}expected.txt\" \
    tb.v ${1}/*.v  > /dev/null 2>&1

    #./tb
    echo test
    done


./cleardecals.sh