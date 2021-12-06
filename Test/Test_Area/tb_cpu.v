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

    logic [31:0] RAM [0:1999];
    logic [31:0] TESTRAM [0:1999];
    logic passed;
    logic [31:0] rdata;
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

    mips_cpu_bus mips_cpu_bus(.clk(clk), .reset(reset), .active(active), .register_v0(register_v0), .address(address), 
    .write(write), .read(read), .waitrequest(waitrequest), .writedata(writedata), .byteenable(byteenable), .readdata(readdata));
    initial begin
        waitrequest=0;
        reset=0;
        /*repeat (100) begin
            $display("active\t\t%d",active);
            $display("address\t\t%d",address);
            $display("write\t\t%d",write);
            $display("read\t\t%d",read);
            $display("writedata %d",writedata);
            $display("byteenable\t%d",byteenable);
            $display("readdata %d",readdata);
            $display("ram[address] %d",RAM[address]);
            $display(" ");
            #2;
        end*/
        #500;
        passed=1;
        for(int i=0;i<2000;i++) begin
            if (RAM[i]!=TESTRAM[i]) begin
                $display("RAM %d, expected %d given %d",i,TESTRAM[i],RAM[i]); 
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

    assign rdata = (address > 3217031167) ? RAM[address-3217030169] : RAM[address];

    logic [7:0] rd1, rd2, rd3, rd4, wd1, wd2, wd3, wd4;

    assign rd1 = rdata[31:24]&{8{byteenable[3]}};
    assign rd2 = rdata[23:16]&{8{byteenable[2]}};
    assign rd3 = rdata[15:8]&{8{byteenable[1]}};
    assign rd4 = rdata[7:0]&{8{byteenable[0]}};

    //assign wd1 = writedata[31:24]&{8{byteenable[3]}};
    //assign wd2 = writedata[23:16]&{8{byteenable[2]}};
    //assign wd3 = writedata[15:8]&{8{byteenable[1]}};
    //assign wd4 = writedata[7:0]&{8{byteenable[0]}};

    always_comb begin
        if (read) begin
            readdata = {rd1,rd2,rd3,rd4};
        end
        if (write) begin
            RAM[address] = writedata;
            //{wd1,wd2,wd3,wd4};
        end
    end

endmodule