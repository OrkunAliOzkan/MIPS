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

    logic [7:0] RAM[0:199];
    logic [7:0] EXPECTEDRAM[0:199];

    parameter INPUT_FILE="BEQ.txt";
    parameter EXPECTED_FILE="BEQexpected.txt";

    logic passed;

    initial begin
        $readmemh(INPUT_FILE, RAM);
        $readmemh(EXPECTED_FILE, EXPECTEDRAM);
    end

    initial begin
        clk=0;
        repeat (400) begin
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
        #400;

        passed=1;
        for(int i=0;i<200;i++) begin
            if(RAM[i]!=EXPECTEDRAM[i])begin
                //$display("RAM %d expected %h given %h",i,EXPECTEDRAM[i],RAM[i]);
                passed = 1'b0;
            end
            $display("RAM %d expected %h given %h",i,EXPECTEDRAM[i],RAM[i]);
        end
        if (passed==1'b1) begin
            $display("Pass");
        end
        else begin
            $display("Fail");
        end
    end

    always_ff @(posedge clk) begin
        if (read) begin
            r4 = (address > 3217031167) ? (RAM[address - 3217031068]) : (RAM[address]) * (byteenable[3]);
            r3 = (address > 3217031167) ? (RAM[address + 1 - 3217031068]) : (RAM[address + 1]) * (byteenable[2]);
            r2 = (address > 3217031167) ? (RAM[address + 2 - 3217031068]) : (RAM[address + 2]) * (byteenable[1]);
            r1 = (address > 3217031167) ? (RAM[address + 3 - 3217031068]) : (RAM[address + 3]) * (byteenable[0]);
            readdata = {r4, r3, r2, r1};
        end
        if (write) begin
            if (byteenable[0]) RAM[address + 3] <= writedata[31:24];
            if (byteenable[1]) RAM[address + 2] <= writedata[23:16];
            if (byteenable[2]) RAM[address + 1] <= writedata[15:8];
            if (byteenable[3]) RAM[address] <= writedata[7:0];
        end
    end
endmodule
