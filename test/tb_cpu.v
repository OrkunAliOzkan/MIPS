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

        repeat (98) begin
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
                //$display("RAM %d expected %h given %h",i,EXPECTEDRAM[i],RAM[i]);
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
        //$display("register_v0: %h", register_v0);
        if (passed==1'b1) begin
            $display("Pass");
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
            case (INPUT_FILE)
                "./test/testcasesnew/ADDIU_1_test.txt": $display("TEST");
                default:  $display("Test return wrong value");
            endcase

            
        end
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
