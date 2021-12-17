module tb_cpu();
    logic [31:0] readdata;
    logic [31:0] writedata;
    logic reset;
    logic active;
    logic [31:0] register_v0;
    logic [31:0] address;
    logic write;
    logic read;
    logic waitrequest;
    logic [3:0] byteenable;
    logic clk;

    logic [7:0] r0;
    logic [7:0] r1;
    logic [7:0] r2;
    logic [7:0] r3;

    logic [7:0] RAM[0:199];
    logic [7:0] EXPECTEDRAM[0:199];

    parameter string INPUT_FILE="";
    parameter EXPECTED_FILE="";

    logic passed;
    string testcase;
    string t1,t2,t3;

    initial begin
        $readmemh(INPUT_FILE, RAM);
        $readmemh(EXPECTED_FILE, EXPECTEDRAM);
    end

    initial begin
        clk = 1;
        reset = 1;
        waitrequest=0;
        
        repeat (2) begin
            #1;
            clk=!clk;
        end

        reset = 0;
        waitrequest=1;

        //$display("waitrequest high");

        repeat (10) begin
            #1;
            clk=!clk;
        end
        waitrequest = 0;
        repeat (88) begin
            #1;
            clk=!clk;
        end

        $finish(0);
    end

    mips_cpu_bus mips_cpu_bus(  .clk(clk), 
                                .reset(reset), 
                                .active(active), 
                                .register_v0(register_v0), 
                                .address(address), 
                                .write(write), 
                                .read(read), 
                                .waitrequest(waitrequest), 
                                .writedata(writedata), 
                                .byteenable(byteenable), 
                                .readdata(readdata));

    initial begin
        #100;

        passed=1;

        for(int i=0;i<200;i++) begin
            if(RAM[i]!=EXPECTEDRAM[i])begin
                $display("RAM %d expected %h given %h",i,EXPECTEDRAM[i],RAM[i]);
                // t1.itoa(i);
                // t2.hextoa(EXPECTEDRAM[i]);
                // t3.hextoa(RAM[i]);
                //comment = {comment,"  ", "RAM ",t1," expected ",t2," given ",t3 };
                // t1 = string'i;
                // comment = {comment,"  ", "RAM ",t1," expected ",string'EXPECTEDRAM[i]," given ",string'RAM[i] };
                passed = 1'b0;
            end
            //$display("RAM %d expected %h given %h",i,EXPECTEDRAM[i],RAM[i]);
        end
        $display("register_v0: %h", register_v0);
        case (INPUT_FILE)
            "./test/testcasesnew/ADDIU_1_test.txt": begin
                    if (register_v0 == 32'h2) begin
                        passed = 1'b1;
                    end
                end
            "./test/testcasesnew/ADDU_1_test.txt": begin
                    if (register_v0 == 32'hf0000001) begin
                        passed = 1'b1;
                    end
                end
            "./test/testcasesnew/ANDI_1_test.txt": begin
                    if (register_v0 == 32'hf0) begin
                        passed = 1'b1;
                    end
                end 
            "./test/testcasesnew/AND_1_test.txt": begin
                if (register_v0 == 32'hc) begin
                    passed = 1'b1;
                end
            end 
            /*
            "./test/testcasesnew/BEQ_1_test.txt": $write("# Does not branch if not equals");
            "./test/testcasesnew/BEQ_2_test.txt": $write("# Branches if equals");
            "./test/testcasesnew/BGEZAL_1_test.txt": $write("# Branches if greater than zero, and register 31 is set to prior address");
            "./test/testcasesnew/BGEZ_1_test.txt": $write("# Branches if greater than equals to zero");
            "./test/testcasesnew/BGEZ_2_test.txt": $write("# Does not branch if less than zero");
            "./test/testcasesnew/BGTZ_1_test.txt": $write("# Branches if greater than zero");
            "./test/testcasesnew/BGTZ_2_test.txt": $write("# Does not branch if 0");
            "./test/testcasesnew/BLEZ_1_test.txt": $write("# Branches if 0");
            "./test/testcasesnew/BLEZ_2_test.txt": $write("# Does not branch if greater than 0");
            "./test/testcasesnew/BLTZAL_1_test.txt": $write("# Does not branch if 1");
            "./test/testcasesnew/BLTZAL_2_test.txt": $write("# Branches if less than 0");
            "./test/testcasesnew/BLTZ_1_test.txt": $write("# Branches if less than 0");
            "./test/testcasesnew/BLTZ_2_test.txt": $write("# Does not branch if 0");
            "./test/testcasesnew/BNE_1_test.txt": $write("# Branches if xFFFFFFFF not equals to 0");
            "./test/testcasesnew/BNE_2_test.txt": $write("# Does not branch when 0 equal 0");
            "./test/testcasesnew/JALR_1_test.txt": $write("# Jumps to register’s value address, register value is correctly changed");
            "./test/testcasesnew/JAL_1_test.txt": $write("# Jumps to immediate value address, register 31 changes to prior address");
            "./test/testcasesnew/JR_1_test.txt": $write("# Jumps to register value address");
            "./test/testcasesnew/J_1_test.txt": $write("# Jumps to immediate value address");*/
            "./test/testcasesnew/LBU_1_test.txt": begin
                if (register_v0 == 32'haa) begin
                    passed = 1'b1;
                end
            end 
            "./test/testcasesnew/LB_1_test.txt": begin
                if (register_v0 == 32'hffffffaa) begin
                    passed = 1'b1;
                end
            end 
            "./test/testcasesnew/LHU_1_test.txt": begin
                if (register_v0 == 32'haabb) begin
                    passed = 1'b1;
                end
            end 
            "./test/testcasesnew/LH_1_test.txt": begin
                if (register_v0 == 32'hffffaabb) begin
                    passed = 1'b1;
                end
            end 
            "./test/testcasesnew/LUI_1_test.txt": begin
                if (register_v0 == 32'hffff0000) begin
                    passed = 1'b1;
                end
            end 
            "./test/testcasesnew/LWL_1_test.txt": begin
                if (register_v0 == 32'hbbaa0000) begin
                    passed = 1'b1;
                end
            end 
            "./test/testcasesnew/LWR_1_test.txt": begin
                if (register_v0 == 32'h00ddccbb) begin
                    passed = 1'b1;
                end
            end 
            "./test/testcasesnew/MTHI_1_test.txt": begin
                if (register_v0 == 32'haabbccdd) begin
                    passed = 1'b1;
                end
            end 
            "./test/testcasesnew/MTLO_1_test.txt": begin
                if (register_v0 == 32'haabbccdd) begin
                    passed = 1'b1;
                end
            end 
            "./test/testcasesnew/MULTU_HI_test.txt": begin
                if (register_v0 == 32'h0f00fffe) begin
                    passed = 1'b1;
                end
            end 
            "./test/testcasesnew/MULTU_LO_test.txt": begin
                if (register_v0 == 32'hfff00001) begin
                    passed = 1'b1;
                end
            end 
            "./test/testcasesnew/ORI_1_test.txt": begin
                if (register_v0 == 32'h0000fff0) begin
                    passed = 1'b1;
                end
            end 
            "./test/testcasesnew/OR_1_test.txt": begin
                if (register_v0 == 32'hffffff00) begin
                    passed = 1'b1;
                end
            end 
            "./test/testcasesnew/SB_1_test.txt": $write("# Store byte xDD to memory");
            "./test/testcasesnew/SH_1_test.txt": $write("# Stores half word xCCDD to memory");
            "./test/testcasesnew/SLLV_1_test.txt": $write("# Shifts xF000 by variable with 4 value");
            "./test/testcasesnew/SLL_1_test.txt": $write("# Shifts xF000 by 4");
            "./test/testcasesnew/SLTIU_1_test.txt": $write("# Stores memory with 0 when rs < immediate");
            "./test/testcasesnew/SLTIU_2_test.txt": $write("# Stores memory with 1 when rs >= immediate");
            "./test/testcasesnew/SLTI_1_test.txt": $write("# Stores memory with 0 when rs < immediate");
            "./test/testcasesnew/SLTI_2_test.txt": $write("# Stores memory with 1 when rs >= immediate");
            "./test/testcasesnew/SLTU_1_test.txt": $write("# Stores memory with 0 when rs < immediate");
            "./test/testcasesnew/SLTU_2_test.txt": $write("# Stores memory with 1 when rs >= immediate");
            "./test/testcasesnew/SLT_1_test.txt": $write("# Stores memory with 0 when rs < immediate");
            "./test/testcasesnew/SLT_2_test.txt": $write("# Stores memory with 1 when rs >= immediate");
            
            "./test/testcasesnew/SRAV_1_test.txt": begin
                if (register_v0 == 32'hffffff00) begin
                    passed = 1'b1;
                end
            end 
            "./test/testcasesnew/SRA_1_test.txt": begin
                if (register_v0 == 32'hffffff00) begin
                    passed = 1'b1;
                end
            end 
            "./test/testcasesnew/SRLV_1_test.txt": begin
                if (register_v0 == 32'h0000ff00) begin
                    passed = 1'b1;
                end
            end 
            "./test/testcasesnew/SRL_1_test.txt": begin
                if (register_v0 == 32'h0000ff00) begin
                    passed = 1'b1;
                end
            end 
            "./test/testcasesnew/SUBU_1_test.txt": begin
                if (register_v0 == 32'h00ff0000) begin
                    passed = 1'b1;
                end
            end 
            "./test/testcasesnew/SWLW_1_test.txt": begin
                if (register_v0 == 32'haabbccdd) begin
                    passed = 1'b1;
                end
            end 
            "./test/testcasesnew/XORI_1_test.txt": begin
                if (register_v0 == 32'h00000ff0) begin
                    passed = 1'b1;
                end
            end 
            "./test/testcasesnew/XOR_1_test.txt": begin
                if (register_v0 == 32'h00ffff00) begin
                    passed = 1'b1;
                end
            end 
        endcase





        if (passed==1'b1) begin
            $write("Pass    ");

        end
        else begin
            $write("Fail ");
            //$write("%s",comment);
            //testcase =string'INPUT_FILE;
            // for (int j=0;j<24;j++ )begin
            //     testcase[j] = INPUT_FILE[j+23];
            // end
            //testcase  =INPUT_FILE;
            //int length = testcase.len();
            //testcase = testcase.substr(0,-8); 
        end
        case (INPUT_FILE)
            "./test/testcasesnew/ADDIU_1_test.txt": begin
                    $display("# Add by 1 immediate");
                end
            "./test/testcasesnew/ADDU_1_test.txt": begin
                    $display("# Add unsigned value by 1");
                end
            "./test/testcasesnew/ANDI_1_test.txt": begin
                    $display("# Bitwise xFFFF AND immediate value x00F0");
                end 
            "./test/testcasesnew/AND_1_test.txt": $display("# Bitwise xFFFF AND x00F0");
            "./test/testcasesnew/BEQ_1_test.txt": $display("# Does not branch if not equals");
            "./test/testcasesnew/BEQ_2_test.txt": $display("# Branches if equals");
            "./test/testcasesnew/BGEZAL_1_test.txt": $display("# Branches if greater than zero, and register 31 is set to prior address");
            "./test/testcasesnew/BGEZ_1_test.txt": $display("# Branches if greater than equals to zero");
            "./test/testcasesnew/BGEZ_2_test.txt": $display("# Does not branch if less than zero");
            "./test/testcasesnew/BGTZ_1_test.txt": $display("# Branches if greater than zero");
            "./test/testcasesnew/BGTZ_2_test.txt": $display("# Does not branch if 0");
            "./test/testcasesnew/BLEZ_1_test.txt": $display("# Branches if 0");
            "./test/testcasesnew/BLEZ_2_test.txt": $display("# Does not branch if greater than 0");
            "./test/testcasesnew/BLTZAL_1_test.txt": $display("# Does not branch if 1");
            "./test/testcasesnew/BLTZAL_2_test.txt": $display("# Branches if less than 0");
            "./test/testcasesnew/BLTZ_1_test.txt": $display("# Branches if less than 0");
            "./test/testcasesnew/BLTZ_2_test.txt": $display("# Does not branch if 0");
            "./test/testcasesnew/BNE_1_test.txt": $display("# Branches if xFFFFFFFF not equals to 0");
            "./test/testcasesnew/BNE_2_test.txt": $display("# Does not branch when 0 equal 0");
            "./test/testcasesnew/JALR_1_test.txt": $display("# Jumps to register’s value address, register value is correctly changed");
            "./test/testcasesnew/JAL_1_test.txt": $display("# Jumps to immediate value address, register 31 changes to prior address");
            "./test/testcasesnew/JR_1_test.txt": $display("# Jumps to register value address");
            "./test/testcasesnew/J_1_test.txt": $display("# Jumps to immediate value address");
            "./test/testcasesnew/LBU_1_test.txt": $display("# Loads 1 byte to register");
            "./test/testcasesnew/LB_1_test.txt": $display("# Loads 1 byte to register");
            "./test/testcasesnew/LHU_1_test.txt": $display("# Loads 2 bytes to register");
            "./test/testcasesnew/LH_1_test.txt": $display("# Loads 2 bytes to register");
            "./test/testcasesnew/LUI_1_test.txt": $display("# Loads immediate value, xFF, to the upper half of word");
            "./test/testcasesnew/LWL_1_test.txt": $display("# Loads left side bytes xAABB from memory");
            "./test/testcasesnew/LWR_1_test.txt": $display("# Loads right side bytes xBBCCDD from memory");
            "./test/testcasesnew/MTHI_1_test.txt": $display("# Changes value of HI to xAABBCCDD - Tests MFHI too");
            "./test/testcasesnew/MTLO_1_test.txt": $display("# Changes value of LO to xAABBCCDD - Tests MFLO too");
            "./test/testcasesnew/MULTU_1_test.txt": $display("# Multiplies FFFFFFF with FFFFFF");
            "./test/testcasesnew/ORI_1_test.txt": $display("# Bitwise xFFFF OR immediate value x00F0");
            "./test/testcasesnew/OR_1_test.txt": $display("# Bitwise xFFFF OR x00F0");
            "./test/testcasesnew/SB_1_test.txt": $display("# Store byte xDD to memory");
            "./test/testcasesnew/SH_1_test.txt": $display("# Stores half word xCCDD to memory");
            "./test/testcasesnew/SLLV_1_test.txt": $display("# Shifts xF000 by variable with 4 value");
            "./test/testcasesnew/SLL_1_test.txt": $display("# Shifts xF000 by 4");
            "./test/testcasesnew/SLTIU_1_test.txt": $display("# Stores memory with 0 when rs < immediate");
            "./test/testcasesnew/SLTIU_2_test.txt": $display("# Stores memory with 1 when rs >= immediate");
            "./test/testcasesnew/SLTI_1_test.txt": $display("# Stores memory with 0 when rs < immediate");
            "./test/testcasesnew/SLTI_2_test.txt": $display("# Stores memory with 1 when rs >= immediate");
            "./test/testcasesnew/SLTU_1_test.txt": $display("# Stores memory with 0 when rs < immediate");
            "./test/testcasesnew/SLTU_2_test.txt": $display("# Stores memory with 1 when rs >= immediate");
            "./test/testcasesnew/SLT_1_test.txt": $display("# Stores memory with 0 when rs < immediate");
            "./test/testcasesnew/SLT_2_test.txt": $display("# Stores memory with 1 when rs >= immediate");
            "./test/testcasesnew/SRAV_1_test.txt": $display("# Performs an arithmetic right shift on xFF000000 by variable of value 16");
            "./test/testcasesnew/SRA_1_test.txt": $display("# Performs an arithmetic right shift on xFF000000 by immediate value 16");
            "./test/testcasesnew/SRLV_1_test.txt": $display("# Performs an logical right shift on xFF000000 by variable of value 16");
            "./test/testcasesnew/SRL_1_test.txt": $display("# Performs an logical right shift on xFF000000 by immediate value 16");
            "./test/testcasesnew/SUBU_1_test.txt": $display("# Subtracts unsigned xFFFF0000 by xFF000000");
            "./test/testcasesnew/SWLW_1_test.txt": $display("# Loads xAABBCCDD to register then stores in memory");
            "./test/testcasesnew/XORI_1_test.txt": $display("# Performs bitwise xFFFF XOR immediate value x00F0");
            "./test/testcasesnew/XOR_1_test.txt": $display("# Performs bitwise xFFFF XOR x00F0");
        endcase        
    end

    always_ff @(posedge clk) begin
        if (read) begin
            r0 = (address > 3217031167) ? (RAM[address - 3217031068]) : (RAM[address]) * (byteenable[0]);
            r1 = (address > 3217031167) ? (RAM[address + 1 - 3217031068]) : (RAM[address + 1]) * (byteenable[1]);
            r2 = (address > 3217031167) ? (RAM[address + 2 - 3217031068]) : (RAM[address + 2]) * (byteenable[2]);
            r3 = (address > 3217031167) ? (RAM[address + 3 - 3217031068]) : (RAM[address + 3]) * (byteenable[3]);
            readdata = {r3, r2, r1, r0};
        end
        if (write) begin
            if (byteenable[0]) RAM[address] <= writedata[7:0];
            if (byteenable[1]) RAM[address + 1] <= writedata[15:8];
            if (byteenable[2]) RAM[address + 2] <= writedata[23:16];
            if (byteenable[3]) RAM[address + 3] <= writedata[31:24];
        end
    end
endmodule
