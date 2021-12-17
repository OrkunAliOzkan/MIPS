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
#$1 is the location of a cpu.v
#we must recompile for every instruction (iterate through)
#we must rename the RAM output txt parameter for each instruction.
#list of instructions?
#problem is the compilation - $1 is the directory i.e. rtl, not the .v file
if [ $# -eq 1 ]
then
    testcases="./test/testcasesnew/*_test.txt"
elif [ $# -eq 2 ]
then
    #temp="*_test.txt"
    temp="*"

    testcases="./test/testcasesnew/${2^^}_${temp}_test.txt" #IF YOU HAVE MULTIPLE TEST CASES, YOU MAY NEED TO ADD AN ASTERISK, LIKE _*
else
    #echo too many/few arguments
    exit 1
fi



#echo $testcases

for test in $testcases #directory containing all the RAM outputs so we can compare against. iterate since it could be one, or all
    do
    #echo $test
    testname=$(basename ${test} _test.txt)
    
    expected_dir="./test/testcasesnew/${testname}_expected.txt"
    
    test_id_lowercase=${testname,,}
    test_lowercase=${test_id_lowercase%_*}

    #echo $test_dir
    #echo $expected_dir

    echo -n ${test_id_lowercase} 
    echo -n " "
    echo -n ${test_lowercase} 
    echo -n " "


    iverilog -Wall -g 2012 -s tb_cpu -o ./test/tb_cpu \
    -P tb_cpu.INPUT_FILE=\"${test}\" \
    -P tb_cpu.EXPECTED_FILE=\"${expected_dir}\" \
    ./test/tb_cpu.v ${1}/*.v  > /dev/null 2>&1 #change mips_cpu_bus to *.v
    
    ./test/tb_cpu

    rm ./test/tb_cpu


    #this should output with display? Ok - i really don't know how it's handled. I'll assume it can fail on the execution level
    #except it can't it really can't. So all the pass fail is inside the testbench I think
    #actually it can fail at execution and print some bs to stdout, 
    #if readmemh fails, but compilation is successful. it'll say unable to open x for reading. 
    #but nothing I can do about that except just make it work in the first place

    done


#./cleardecals.sh
