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

    logic [31:0] RAM[0:2000];
    initial begin
        //Data We Will Utilize
        RAM[100] = 123;
        RAM[101] = 404;
        RAM[102] = 3;
        RAM[103] = 4;
        RAM[104] = 32'b1001;
        RAM[105] = 32'b0101;

        //Instruction Data  TODO:   Change from $1
        RAM[1168] = 32'b10001100000000010000000001100100;//LW $1, 100,      $0 $1=123
        RAM[1172] = 32'b00000000001000000000000000010001;//MTHI $1          HI=123
        RAM[1176] = 32'b10001100000000010000000001100101;//LW $1, 101,      $1=404
        RAM[1180] = 32'b00000000001000000000000000010011;//MTLO $1          LO=404
        RAM[1184] = 32'b00000000000000000000100000010000;//MFHI $1          $1=HI=123
        RAM[1188] = 32'b10101100000000010000000011001000;//SW $1, 200, $0 RAM[200]=123

        RAM[1192] = 32'b00000000000000000000100000010010;//MFLO $1          $1 = 404
        RAM[1196] = 32'b10101100000000010000000011001001;//SW $1, 201, $0   RAM[201] = 404

        RAM[1200] = 32'b10001100000000010000000001100110;//LW $1, 102, $0
        RAM[1204] = 32'b10001100000000100000000001100111;//LW $2, 103, $0
        RAM[1208] = 32'b00000000010000010000000000011000;//MULT $1, $2  <-  TODO:   Problematic
        RAM[1212] = 32'b00000000000000000001100000010010;//MFLO $3  FIXME:  change
        RAM[1216] = 32'b10101100000000110000000011001011;//SW $3, 203, $0

        RAM[1220] = 32'b10001100000000010000000001101000;//LW $1, 104, $0
        RAM[1224] = 32'b10001100000000100000000001101001;//LW $2, 105, $0
        RAM[1228] = 32'b00000000001000100001100000100101;//OR $3, $1, $2
        RAM[1232] = 32'b10101100000000110000000011001100;//SW $3, 204, $0

        RAM[1236] = 32'b00110100001000110000000000000101;//ORI $3, $1, 0b0101
        RAM[1240] = 32'b10101100000000110000000011001101;//SW $3, 205, $0

        RAM[1244] = 32'b10100000000000010000000011001110;//SB $1, 206, $0

        RAM[1248] = 32'b10100100000000010000000011001111;//SH $1, 207, $0

        RAM[1252] = 32'b00000000000000010001100010000000;//SLL $3, $1, 2  <-  TODO:   Problematic
        RAM[1256] = 32'b10101100000000110000000011010001;//SW $3, 209, $0

        RAM[1260] = 32'b00000000001000100001100000101010;//SLT $3, $1, $2  <-  TODO:   Problematic
        RAM[1264] = 32'b10101100000000110000000011010010;//SW $3, 210, $0

        RAM[1268] = 32'b00101000001000110000000000001111;//SLTI $3, $1, 0b1111
        RAM[1272] = 32'b10101100000000110000000011010011;//SW $3, 211, $0

        RAM[1276] = 32'b00101100001000110000000000001111;//SLTIU $3, $1, 0b1111
        RAM[1280] = 32'b10101100000000110000000011010100;//SW $3, 212, $0

        RAM[1284] = 32'b00000000001000100001100000101011;//SLTU $3, $1, $2
        RAM[1288] = 32'b10101100000000110000000011010101;//SW $3, 213, $0
        RAM[1292] = 32'b00000000000000010001100011000011;//SRA $3, $1, 3
        RAM[1296] = 32'b10101100000000110000000011010110;//SW $3, 214, $0
        RAM[1300] = 32'b00000000010000010001100000000111;//SRAV $3, $1, $2
        RAM[1304] = 32'b10101100000000110000000011010111;//SW $3, 215, $0
        RAM[1308] = 32'b00000000000000010001100011000010;//SRL $3, $1, 3
        RAM[1312] = 32'b10101100000000110000000011011000;//SW $3, 216, $0
        RAM[1316] = 32'b00000000010000010001100000000110;//SRLV $3, $1, $2
        RAM[1320] = 32'b10101100000000110000000011011001;//SW $3, 217, $0
        RAM[1324] = 32'b00000000001000100001100000100011;//SUBU $3, $1, $2
        RAM[1328] = 32'b10101100000000110000000011011010;//SW $3, 218, $0
        RAM[1332] = 32'b00000000001000100001100000100110;//XOR $3, $1, $2
        RAM[1336] = 32'b10101100000000110000000011011011;//SW $3, 219, $0
        RAM[1340] = 32'b00111000001000110000000000000101;//XORI $3, $1, 0b101
        RAM[1344] = 32'b10101100000000110000000011011100;//SW $3, 220, $0

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

        repeat (200) begin
            #0.5;
            $display("%d",address);
        end

        for(int i=0; i<500; i++) begin
            $display("%d %d",i, RAM[i]);
        end
        // We are checking each part of the RAM to see which instruction works and which one does not
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
