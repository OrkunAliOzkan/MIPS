module tb_cpu();
    logic[31:0] readdata;
    logic [4294967295:0] RAM [31:0];

    initial begin
        //Data We Will Utilize
        RAM[100] = 123;
        RAM[101] = 404;
        RAM[102] = 3;
        RAM[103] = 4;
        RAM[104] = 32'b1001;
        RAM[105] = 32'b0101;

        //Instruction Data
        RAM[3217031168] = ;//LW $1, 100, $0
        RAM[3217031169] = ;//MTHI $1
        RAM[3217031170] = ;//LW $1, 101, $0
        RAM[3217031171] = ;//MTLO $1
        RAM[3217031172] = ;//MTHI $1
        RAM[3217031173] = ;//SW $1, 200, $0
        RAM[3217031174] = ;//MFLO $1
        RAM[3217031175] = ;//SW $1, 201, $0
        RAM[3217031176] = ;//LW $1, 102, $0
        RAM[3217031177] = ;//LW $2, 103, $0
        RAM[3217031178] = ;//MULT $1, $2
        RAM[3217031179] = ;//MFLO $3
        RAM[3217031180] = ;//SW $3, 203, $0
        RAM[3217031181] = ;//LW $1, 104, $0
        RAM[3217031182] = ;//LW $2, 105, $0
        RAM[3217031183] = ;//OR $3, $1, $2
        RAM[3217031184] = ;//SW $3, 204, $0
        RAM[3217031185] = ;//ORI $3, $1, 0b0101
        RAM[3217031186] = ;//SW $3, 205, $0
        RAM[3217031187] = ;//SB $1, 206, $0
        RAM[3217031188] = ;//SH $1, 207, $0
        RAM[3217031189] = ;//SLL $3, $1, 2
        RAM[3217031190] = ;//SW $3, 209, $0
        RAM[3217031191] = ;//SLT $3, $1, $2
        RAM[3217031192] = ;//SW $3, 210, $0
        RAM[3217031193] = ;//SLTI $3, $1, 0b1111
        RAM[3217031194] = ;//SW $3, 211, $0
        RAM[3217031195] = ;//SLTIU $3, $1, 0b1111
        RAM[3217031196] = ;//SW $3, 212, $0
        RAM[3217031197] = ;//SLTU $3, $1, $2
        RAM[3217031198] = ;//SW $3, 213, $0
        RAM[3217031199] = ;//SRA $3, $1, 3
        RAM[3217031200] = ;//SW $3, 214, $0
        RAM[3217031201] = ;//SRAV $3, $1, $2
        RAM[3217031202] = ;//SW $3, 215, $0
        RAM[3217031203] = ;//SRL $3, $1, 3
        RAM[3217031204] = ;//SW $3, 216, $0
        RAM[3217031205] = ;//SRLV $3, $1, $2
        RAM[3217031206] = ;//SW $3, 217, $0
        RAM[3217031207] = ;//SUBU $3, $1, $2
        RAM[3217031208] = ;//SW $3, 218, $0
        RAM[3217031209] = ;//XOR $3, $1, $2
        RAM[3217031210] = ;//SW $3, 219, $0
        RAM[3217031211] = ;//XORI $3, $1, 0b101
        RAM[3217031212] = ;//SW $3, 220, $0

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
        if (RAM[204]==0'b1101 && RAM[205]==0'b1101) begin
            $display("OR Passed");
            $display("ORI Passed");
        end
        else begin
            $display("OR Failed");
            $display("ORI Failed");
        end
        if (RAM[206]==0'b1001 && RAM[207]==0'b1001) begin
            $display("SB Passed");
            $display("SH Passed");
        end
        else begin
            $display("SB Failed");
            $display("SH Failed");
        end
        if (RAM[208]==0'b100100 && RAM[209]==0'b100100000) begin
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
        if (RAM[218]==0'b100) begin
            $display("SUBU Passed");
        end
        else begin
            $display("SUBU Failed");
        end
        if (RAM[219]==0'b1100) begin
            $display("XOR Passed");
        end
        else begin
            $display("XOR Failed");
        end
        if (RAM[220]==0'b1100) begin
            $display("XORI Passed");
        end
        else begin
            $display("XORI Failed");
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