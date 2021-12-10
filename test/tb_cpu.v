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

    logic [7:0] r1;
    logic [7:0] r2;
    logic [7:0] r3;
    logic [7:0] r4;
    logic [7:0] w1;
    logic [7:0] w2;
    logic [7:0] w3;
    logic [7:0] w4;

    logic [7:0] RAM[0:199];
    logic [7:0] TESTRAM[0:199];

    parameter RAM_FILE="";
    parameter OUT_FILE="";

    logic passed;

    initial begin
        /*//Data We Will Utilize:
        RAM[4] = 8'hFC;
        RAM[5] = 8'h18;
        RAM[6] = 8'h3A;
        RAM[7] = 8'h5C;
        // we write to here:
        //RAM[8] = 8'h0;
        //RAM[9] = 8'h0;
        //RAM[10] = 8'h0;
        //RAM[11] = 8'h0;

        //LW $1, 4, $0
        RAM[100] = 8'h04;
        RAM[101] = 8'h00;
        RAM[102] = 8'h01;
        RAM[103] = 8'h8C;
        //SW $1, 8, $0
        RAM[104] = 8'h08;
        RAM[105] = 8'h00;
        RAM[106] = 8'h01;
        RAM[107] = 8'hAC;*/
        $readmemh(RAM_FILE, RAM);
        $readmemh(OUT_FILE, TESTRAM);
    end

    initial begin
        clk=0;
        repeat (40) begin
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
        waitrequest=0;
        reset=0;
        #30;

        passed=1;
        for(int i=0;i<200;i++) begin
            if(RAM[i]!=TESTRAM[i])begin
                $display("RAM %d expected %h given %h",i,TESTRAM[i],RAM[i]);
                passed = 1'b0;
            end
            //$display("RAM %d expected %d given %d",i,TESTRAM[i],RAM[i]);
        end
        if (passed==1'b1) begin
            $display("Pass");
        end
        else begin
            $display("Fail");
        end
    end

    assign r4 = (address > 3217031167) ? (RAM[address - 3217031068]) : (RAM[address]);
    assign r3 = (address > 3217031167) ? (RAM[address + 1 - 3217031068]) : (RAM[address + 1]);
    assign r2 = (address > 3217031167) ? (RAM[address + 2 - 3217031068]) : (RAM[address + 2]);
    assign r1 = (address > 3217031167) ? (RAM[address + 3 - 3217031068]) : (RAM[address + 3]);
    /*
    */
    assign w1 = writedata[31:24];
    assign w2 = writedata[23:16];
    assign w3 = writedata[15:8];
    assign w4 = writedata[7:0];

    always_comb begin
        if (read) begin
            if (address > 3217031167) begin
                /*
                r4 = RAM[address - 3217031068] * byteenable[0];
                r3 = RAM[address + 1 - 3217031068] * byteenable[1];
                r2 = RAM[address + 2 - 3217031068] * byteenable[2];
                r1 = RAM[address + 3 - 3217031068] * byteenable[3];
                
                r4 = RAM[address - 3217031068];
                r3 = RAM[address + 1 - 3217031068];
                r2 = RAM[address + 2 - 3217031068];
                r1 = RAM[address + 3 - 3217031068];
                */
                readdata = {r1, r2, r3, r4};
            end
            else begin
                /*
                r4 = RAM[address] * byteenable[0];
                r3 = RAM[address + 1] * byteenable[1];
                r2 = RAM[address + 2] * byteenable[2];
                r1 = RAM[address + 3] * byteenable[3];
                
                r4 = RAM[address];
                r3 = RAM[address + 1];
                r2 = RAM[address + 2];
                r1 = RAM[address + 3];
                */
                readdata = {r1, r2, r3, r4};
            end
        end
        if (write) begin
            /*
            w1 = writedata[31:24] * byteenable[3];
            w2 = writedata[23:16] * byteenable[2];
            w3 = writedata[15:8] * byteenable[1];
            w4 = writedata[7:0] * byteenable[0];
            */
            
            RAM[address + 3] = w1;
            RAM[address + 2] = w2;
            RAM[address + 1] = w3;
            RAM[address] = w4;
        end
    end
endmodule

/*
    input logic clk, V
    input logic reset,
    output logic active,
    output logic[31:0] register_v0,
    output logic[31:0] address,
    output logic write, V
    output logic read, V
    input logic waitrequest,
    output logic[31:0] writedata, V
    output logic[3:0] byteenable,
    input logic[31:0] readdata V
*/
