module tb_cpu();
    logic[31:0] readdata;
    logic [31:0] RAM [4294967295:0];

    initial begin
        //Data We Will Utilize
        RAM[299] = 0;
        RAM[300] = 0;
        RAM[301] = 0;
        RAM[302] = 0; 
        RAM[303] = 3217031324;
        RAM[305] = 45;
        RAM[307] = 47;
        RAM[309] = 49;
        RAM[311] = 51;

        //Instruction Data
        RAM[3217031168] = 0x24130005; //ADDIU $s3, $0, d'5'
        RAM[3217031172] = 0x00139021; //ADDU $s2, $0, $s3
        RAM[3217031176] = 0x2674000F; //ADDIU $s4, $s3, d'15'
        RAM[3217031180] = 0x02748024; //AND $s0, $s3, $s4
        RAM[3217031180] = 0x32710010; //ANDI $s1, $s4, d'16'
        RAM[3217031184] = 0x12710003; //BEQ $s3, $s1, d'3'
        RAM[3217031188] = 0x10000003; //BEQ $0, $0, d'3'
        RAM[3217031200] = 0x04010003; //BGEZ $0, d'3'
        RAM[3217031212] = 0x04110003; //BGEZAL $0, d'3'
        RAM[3217031224] = 0xAC1F012B; //SW r31, 299, $0   Mem[299]=r31
        RAM[3217031228] = 0x1C000003; //BGTZ $0, d'3'
        RAM[3217031232] = 0x1E200003; //BGTZ $s1, d'3'
        RAM[3217031244] = 0x16200003; //BNE $s1, $0, d'3'
        RAM[3217031256] = 0x0293001A; //DIV $s4, $s3
        RAM[3217031260] = 0x0000A812; //MFLO $s5
        RAM[3217031264] = 0xAC15012C; //SW $s5, 300, $0   Mem[300]=4
        RAM[3217031268] = 0x0293001B; //DIVU $s4, $s3
        RAM[3217031272] = 0x0000A812; //MFLO $s5
        RAM[3217031276] = 0xAC15012D; //SW $s5, 301, $0   Mem[301]=4
        RAM[3217031280] = 0x0BC0007C; //J '3217031292'
        RAM[3217031292] = 0x0FC00088; //JAL '3217031304'
        RAM[3217031304] = 0xAC1F012E; //SW $r31, 302, $0  Mem[302]=r31
        RAM[3217031308] = 0x8C16012F; //LW $s6, 303, $0
        RAM[3217031312] = 0x02C0B809; //JALR $s7, $s6
        RAM[3217031324] = 0xAC160130; //SW $s6, 304, $0   Mem[304]=Mem[$s6]
        RAM[3217031328] = 0x80160131; //LB $s6, 305, $0   
        RAM[3217031332] = 0xAC160132; //SW $s6, 306, $0   Mem[306]=Mem[305] ?
        RAM[3217031336] = 0x90160135; //LBU $s6, 307, $0
        RAM[3217031340] = 0xAC160134; //SW $s6, 308, $0  h134 Mem[308]=Mem[307] ?
        RAM[3217031344] = 0x84160135; //LH $s6, 309, $0  h135
        RAM[3217031348] = 0xAC160136; //SW $s6, 310, $0  h136 Mem[310]=Mem[309] ?
        RAM[3217031352] = 0x94160137; //LHU $s6, 311, $0 h137
        RAM[3217031356] = 0xAC160138; //SW $s6, 312, $0 h138  Mem[312]=Mem[311] ?
        RAM[3217031360] = 0x3C161001; //LUI $s6, h'1001', $0 
        RAM[3217031364] = 0xAC110141; //SW $s1, 321, $0 h141  Mem[321]=5
        RAM[3217031368] = 0xAC130143; //SW $s3, 323, $0 h143  Mem[323]=5
        RAM[3217031372] = 0xAC140144; //SW $s4, 324, $0 h144  Mem[324]=20
        RAM[3217031376] = 0xAC150145; //SW $s5, 325, $0 h145  Mem[325]=4
        RAM[3217031380] = 0xAC160146; //SW $s6, 326, $0 h146  Mem[326]=h'10010000'
        RAM[3217031384] = 0xAC170147; //SW $s7, 327, $0 h147  Mem[327]=3217031312
        RAM[3217031388] = 0xAC120142; //SW $s2, 322, $0 h142  Mem[322]=5
        RAM[3217031392] = 0xAC100140; //SW $s0, 320, $0 h140  Mem[320]=5

    end

    initial begin
        clk=0;
        repeat (500) begin
            #1;
            clk=!clk;
        end
        $finish(0);
    end

    cpu cpu(.clk(clk), .reset(reset), .active(active), .register_v0(register_v0), .address(address), 
    .write(write), .read(read), .waitrequest(waitrequest), .writedata(writedate), .byteenable(byteenable), .readdata(readdata));

    initial begin
        waitrequest=0;
        reset=0;
        #500;
        // We are checking each part of the RAM to see which instruction works and which one does not
        if (RAM[322]==5) begin
            $display("ADDU Passed");
        end
        else begin
            $display("ADDU Failed");
        end
        if (RAM[321]==16 && RAM[324]==20 && RAM[321]==5) begin
            $display("ADDIU Passed");
            $display("AND Passed");
            $display("ANDIU Passed");
        end
        else begin
            $display("ADDIU Failed");
            $display("AND Failed");
            $display("ANDIU Failed");
        end
        if (RAM[320]==5) begin
            $display("AND Passed");
        end
        else begin
            $display("AND Failed");
        end
        if (RAM[299]==3217031224) begin
            $display("BEQ Passed");
            $display("BGEZAL Passed");
        end
        else begin
            $display("BEQ Failed");
            $display("BGEZAL Failed");
        end
        if (RAM[300]==4) begin
            $display("BNE Passed");
            $display("DIV Passed");
            $display("BGTZ Passed");
        end
        else begin
            $display("BGTZ Failed");
            $display("BNE Failed");
            $display("DIV Failed");
        end
        if (RAM[301]==4) begin
            $display("DIVU Passed");
        end
        else begin
            $display("DIVU Failed");
        end
        if (RAM[302]==3217031292) begin
            $display("J Passed");
            $display("JAL Passed");
        end
        else begin
            $display("J Failed");
            $display("JAL Failed");
        end
        if (RAM[327]==3217031312) begin
            $display("JALR Passed");
        end
        else begin
            $display("JALR Failed");
        end
        if (RAM[306]==45) begin
            $display("LB Passed");
        end
        else begin
            $display("LB Failed");
        end
        if (RAM[308]==47) begin
            $display("LBU Passed");
        end
        else begin
            $display("LBU Failed");
        end
        if (RAM[310]==49) begin
            $display("LH Passed");
        end
        else begin
            $display("LHU Failed");
        end
        if (RAM[326]==h'10010000') begin
            $display("LUI Passed");
        end
        else begin
            $display("LUI Failed");
        end
    end

    always begin
        if (read) begin
            readdata <= RAM[address];
        end
        if (write) begin
            RAM[address] <= writedata;
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
