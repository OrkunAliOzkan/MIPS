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

    logic [7:0] RAM[0:200];
    initial begin
        //Data We Will Utilize:
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
        //SW $4, 8, $0
        RAM[104] = 8'h08;
        RAM[105] = 8'h00;
        RAM[106] = 8'h01;
        RAM[107] = 8'hAC;
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

        repeat (100) begin
            #2;
            //$display("Working?");
            //$display("R4:\t%h", r4);
            //$display("R3:\t%h", r3);
            //$display("R2:\t%h", r2);
            //$display("R1:\t%h", r1);
            $display("DATA BACK:\t%h", {r1,r2,r3,r4});
            $display("DATA TO WRITE:\t%h", {w1,w2,w3,w4});
            $display("address:\t%d", address);


            //$display("address:\t%d", address - 3217031068);

            $display("%d %d",8, RAM[8]);
            $display("%d %d",9, RAM[9]);
            $display("%d %d",10, RAM[10]);
            $display("%d %d",11, RAM[11]);
        end
        
    end
            //$display("%d", $unsigned(16'hFFFF));
            //$display("--------------------");
            //for(int i=200; i<201; i++) begin
            //    $display("%d %d",i, RAM[i]);
            //end
            // We are checking each part of the RAM to see which instruction works and which one does not
        /*
            if (RAM[200]==123 && RAM[201]==404) begin
                $display("MTHI Passed");
                $display("MTLO Passed");
                $display("MFHI Passed");
                $display("MFLO Passed");
            end
            else begin
                $display("MTHI Failed");
                $display("MTLO Failed");
                $display("MFHI Failed");
                $display("MFLO Failed");
            end
            if (RAM[202]==12 && RAM[203]==12) begin
                $display("MULT Passed");
                $display("MULTU Passed");
            end
            else begin
                $display("MULT Failed");
                $display("MULTU Failed");
            end
            if (RAM[204]==32'b1101 && RAM[205]==32'b1101) begin
                $display("OR Passed");
                $display("ORI Passed");
            end
            else begin
                $display("OR Failed");
                $display("ORI Failed");
            end
            if (RAM[206]==32'b1001 && RAM[207]==32'b1001) begin
                $display("SB Passed");
                $display("SH Passed");
            end
            else begin
                $display("SB Failed");
                $display("SH Failed");
            end
            if (RAM[208]==32'b100100 && RAM[209]==32'b100100000) begin
                $display("SLL Passed");
                $display("SLLV Passed");
            end
            else begin
                $display("SLL Failed");
                $display("SLLV Failed");
            end
            if (RAM[210]==0) begin
                $display("SLT Passed");
            end
            else begin
                $display("SLT Failed");
            end
            if (RAM[211]==1) begin
                $display("SLTI Passed");
            end
            else begin
                $display("SLTI Failed");
            end
            if (RAM[212]==1) begin
                $display("SLTIU Passed");
            end
            else begin
                $display("SLTIU Failed");
            end
            if (RAM[213]==0) begin
                $display("SLTU Passed");
            end
            else begin
                $display("SLTU Failed");
            end
            if (RAM[214]==1) begin
                $display("SRA Passed");
            end
            else begin
                $display("SRA Failed");
            end
            if (RAM[215]==0) begin
                $display("SRAV Passed");
            end
            else begin
                $display("SRAV Failed");
            end
            if (RAM[216]==1) begin
                $display("SRL Passed");
            end
            else begin
                $display("SRL Failed");
            end
            if (RAM[217]==0) begin
                $display("SRLV Passed");
            end
            else begin
                $display("SRLV Failed");
            end
            if (RAM[218]==32'b100) begin
                $display("SUBU Passed");
            end
            else begin
                $display("SUBU Failed");
            end
            if (RAM[219]==32'b1100) begin
                $display("XOR Passed");
            end
            else begin
                $display("XOR Failed");
            end
            if (RAM[220]==32'b1100) begin
                $display("XORI Passed");
            end
            else begin
                $display("XORI Failed");
            end
        end
    */

    /*
        assign r1 = readdata[31:24] * byteenable[3];
        assign r2 = readdata[23:16] * byteenable[2];
        assign r3 = readdata[15:8] * byteenable[1];
        assign r4 = readdata[7:0] * byteenable[0];

        assign w1 = writedata[31:24] * byteenable[3];
        assign w2 = writedata[23:16] * byteenable[2];
        assign w3 = writedata[15:8] * byteenable[1];
        assign w4 = writedata[7:0] * byteenable[0];
    */
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
