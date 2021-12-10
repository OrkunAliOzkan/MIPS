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


if [ $# -eq 1 ]
then
    testcases="*_test.txt"
elif [ $# -eq 2 ]
then
    testcases="${2^^}_test.txt" #IF YOU HAVE MULTIPLE TEST CASES, YOU MAY NEED TO ADD AN ASTERISK, LIKE _*
else
    echo too many/few arguments
    exit 1
fi



#echo $testcases

for test in $testcases #directory containing all the RAM outputs so we can compare against. iterate since it could be one, or all
    do
    #
    testname=$(basename ${test} _test.txt)
    #echo $test
    expected_dir="${testname}_expected.txt"
    test_dir="${testname}_test.txt"
    #echo $test_dir
    #echo $expected_dir

    iverilog -Wall -g 2012 -s tb_cpu -o test/tb_cpu \
    -P tb_cpu.RAM_FILE=\"${test}\" \
    -P tb_cpu.OUT_FILE=\"${expected_dir}\" \
    test/tb_cpu.v ${1}/mips_cpu_bus.v  #> /dev/null 2>&1 #change mips_cpu_bus to *.v LKJSDFHSD;LIFHSD
    
    #cd /test/Test_Area
    ./test/tb_cpu
    #cd ..
    #cd ..

    #this should output with display? Ok - i really don't know how it's handled. I'll assume it can fail on the execution level
    #except it can't it really can't. So all the pass fail is inside the testbench I think

    #so the problem I have is that I don't want to have to be in the directory of test bench to run it. It will have to deal with the fact that
    #the cwd will be root, not /test

    #echo test
    done


#./cleardecals.sh