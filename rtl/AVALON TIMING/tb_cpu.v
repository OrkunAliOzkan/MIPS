module tb_cpu();
    logic clk;
    logic reset;
    logic waitrequest;
    logic passed;
    logic [31:0] RAM [0:1999];
    logic [31:0] TESTRAM [0:1999];
    parameter RAM_FILE="";
    parameter OUT_FILE="";

    initial begin
        //initialize the RAM
        $display("%s",RAM_FILE);
        $display("%s",OUT_FILE);
        for (int i=0;i<2000;i++) begin
            RAM[i]=0;
            TESTRAM[i]=0;
        end

        //load text file into RAM
        $readmemh(RAM_FILE, RAM);
        $readmemh(OUT_FILE, TESTRAM);

    end

    initial begin
        clk=0;
        repeat (500) begin
            #1;
            clk=!clk;
        end
        $finish(0);
    end

    //mips_cpu_bus mips_cpu_bus(.clk(clk), .reset(reset), .active(active), .register_v0(register_v0), .address(address), 
    //.write(write), .read(read), .waitrequest(waitrequest), .writedata(writedata), .byteenable(byteenable), .readdata(readdata));

    initial begin
        waitrequest=0;
        reset=0;
        #500;
        passed=1;
        for(int i=0;i<2000;i++) begin
            if (RAM[i]!=TESTRAM[i]) begin
                passed=0;
            end
        end
        if (passed==1) begin
            $display("%s passed",RAM_FILE);
        end
        else begin
            $display("%s failed",RAM_FILE);
        end
    end

    always_comb begin
        if (read) begin
            if (address > 3217031167) begin
                readdata = RAM[address-3217030000];
            end
            else begin
                readdata = RAM[address];
            end
        end
        if (write) begin
            RAM[address] = writedata;
        end
    end

endmodule