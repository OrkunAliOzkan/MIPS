module mips_cpu_bus(
    /* Standard signals */
    input logic clk,
    input logic reset,
    output logic active,
    output logic[31:0] register_v0,

    /* Avalon memory mapped bus controller (master) */
    output logic[31:0] address,
    output logic write,
    output logic read,
    input logic waitrequest,
    output logic[31:0] writedata,
    output logic[3:0] byteenable,
    input logic[31:0] readdata
);

    //Define all states
    typedef enum logic[2:0]
    {
        IF = 3'd0,      //Instruction Fetch
        ID = 3'd1,      //Instruction decode/Register fetch cycle
        EX = 3'd2,      //Execution/Effective address cycle
        MEM = 3'd3,     //Memory access 
        WB = 3'd4,      //Write-back cycle 
        HALT = 3'd5
    } state_t;
    // define state variable
    state_t state;

    //Define Opcodes
    typedef enum logic[5:0]
    {
        OPCODE_BEQ = 6'd4,
        OPCODE_BGTZ = 6'd7,
        OPCODE_BLEZ = 6'd6,
        OPCODE_BNE = 6'd5,

        OPCODE_ADDIU = 6'd9,
        OPCODE_SLTIU = 6'd11,
        OPCODE_LUI = 6'd15,
        OPCODE_ANDI = 6'd12,
        OPCODE_ORI = 6'd13,
        OPCODE_SLTI = 6'd10,
        OPCODE_XORI = 6'd14,

        OPCODE_LB = 6'd32,
        OPCODE_LBU = 6'd36,
        OPCODE_LH = 6'd33,
        OPCODE_LHU = 6'd37,
        OPCODE_LW = 6'd35,
        OPCODE_SB = 6'd40,
        OPCODE_SH = 6'd41,
        OPCODE_SW = 6'd43,

        OPCODE_LWR = 6'd38,
        OPCODE_LWL = 6'd34
    }opcode_t;

    typedef enum logic[5:0]
    {
        FC_ADDU = 6'd33,
        FC_SUBU = 6'd35,
        FC_AND = 6'd36,
        FC_OR = 6'd37,
        FC_SLT = 6'd42,
        FC_SLTU = 6'd43,
        FC_XOR = 6'd38,
        FC_SLL = 6'd0,
        FC_SLLV = 6'd4,
        FC_SRA = 6'd3,
        FC_SRAV = 6'd7,
        FC_SRL = 6'd2,
        FC_SRLV = 6'd6,
        FC_DIV = 6'd26,
        FC_DIVU = 6'd27,
        FC_MULT = 6'd24,
        FC_MULTU = 6'd25,

        FC_MFHI = 6'd16,
        FC_MTHI = 6'd17,
        FC_MFLO = 6'd18,
        FC_MTLO = 6'd19,

        FC_JALR = 6'd9,
        FC_JR = 6'd8
    } fcode_t;

    //Create register file
    logic signed [31:0] register [31:0] ; //  This is defined as signed to emphasise operations may be unsigned
    logic RegWrite;

    //Create HI, LO registers
    logic[31:0] HI;
    logic[31:0] LO;

    //Program counter logic
    logic[31:0] PC, PC_next, PC_jump;

    //Byte Enable logic
    logic[1:0] ByteEnableLogic;
    //Memory access logic
    logic lOp;
    logic sOp;

    //ALU output
    logic [63:0] ALUout;

    //Create IR Block to hold information through all cycles.
    logic[31:0] InstructionReg;

    logic[5:0] IR_opcode;
    logic[4:0] IR_rs;
    logic[4:0] IR_rt;
    logic[4:0] IR_rd;
    logic[4:0] IR_shmat;
    logic[5:0] IR_funct;
    logic[15:0] IR_address_immediate;
    logic[25:0] IR_targetAddress;

    initial begin
        PC = 32'hBFC00000;
        for(integer i = 0; i < 32; i++) begin
            register[i] <= 32'h0;
        end
        state = IF;
    end

    always @(*) begin
        case(state)
            (IF): begin
                //Fetching next instruction from memory using PC as address. So need to read from RAM
                read = 1;
                write = 0;
                RegWrite = 0;
                
                InstructionReg = readdata;
                address = PC;
            end
            (ID): begin
                //Not writing or reading anything. Just decoding the instruction. Putting in IR.
                read = 0;
                write = 0;
                RegWrite = 0;
                address = PC;
            end
            (EX): begin
                // For ALU calculations, no reading or writing done.
                lOp = ((IR_opcode == OPCODE_LB) || (IR_opcode == OPCODE_LBU) || (IR_opcode == OPCODE_LH) || (IR_opcode == OPCODE_LHU) || (IR_opcode == OPCODE_LW)
                        || (IR_opcode == OPCODE_LWL) || (IR_opcode == OPCODE_LWR));
                sOp = ((IR_opcode == OPCODE_SB) || (IR_opcode == OPCODE_SW) || (IR_opcode == OPCODE_SH));
                ByteEnableLogic = (register[IR_rs] + { 16'd0, IR_address_immediate }) % 4; //Modulo doesnt work properly //FIXME: How will this work with bigendian

                read = 0;
                write = 0;
                if(IR_opcode == 6'd3) RegWrite = 1;
                else RegWrite = 0;
                address = PC;
            end
            (MEM): begin
                // Read or write to memory if Load/Store. no other instructions go here.
                address = (register[IR_rs] + { 16'd0, IR_address_immediate }) - ByteEnableLogic;
                if (lOp) begin
                    read = 1;
                    write = 0;
                    RegWrite = 0;
                end
                else if (sOp) begin
                    read = 0;
                    write = 1;
                    RegWrite = 0;
                end
                if (waitrequest) begin  //FIXME: Made a change here
                    read = 0;
                    write = 0;
                end
            end
            (WB): begin
                //Will be writing registers.
                address = PC;
                read = 0;
                write = 0;
                RegWrite = 1;
            end
            (HALT): begin
                
            end

        endcase
    end

   always_ff @(posedge clk) begin
        
        if(reset) begin
            active <= 1;
            PC <= 32'hBFC00000;
            PC_next <= 32'hBFC00004;
            PC_jump <= 32'h0;
            state <= IF;
            for(integer i = 0; i < 32; i++) begin
                register[i] <= 32'd0;
            end
        end

        case(state)
            (IF): begin
                //Fetching nest instruction from memory using PC as address. So need to read from RAM
                byteenable <= 4'b1111;

                //Define next state.
                if(PC_jump != 32'd0) begin
                    PC_next <= PC_jump;
                    PC_jump <= 0;
                end
                else begin
                    PC_next <= PC + 32'd4;
                end
                state <= ID;
            end
            (ID): begin
                // Set up instruction register
                
                IR_opcode = InstructionReg[31:26];
                IR_rs = InstructionReg[25:21];
                IR_rt = InstructionReg[20:16];
                IR_rd = InstructionReg[15:11];
                IR_shmat = InstructionReg[10:6];
                IR_funct = InstructionReg[5:0];
                IR_targetAddress = InstructionReg[25:0];
                IR_address_immediate = InstructionReg[15:0];

                state <= EX;
            end
            (EX): begin
                //ALU Calcuations
                // Get Address with offset. Make sure the address is multiple of 4. 
                if (sOp || lOp) begin                        
                    if ((IR_opcode == OPCODE_SB) || (IR_opcode == OPCODE_LB) || (IR_opcode == OPCODE_LBU)) begin
                        case(ByteEnableLogic)
                            (0) : byteenable <= (4'd8);                   //  Byte enable the first byte
                            (1) : byteenable <= (4'd4);                   //  Byte enable the second byte
                            (2) : byteenable <= (4'd2);                   //  Byte enable the third byte
                            (3) : byteenable <= (4'd1);                   //  Byte enable the fourth byte
                        endcase
                        writedata = { register[IR_rt][31:24] , register[IR_rt][31:24] , register[IR_rt][31:24] , register[IR_rt][31:24] };
                    end
                    else if ((IR_opcode == OPCODE_SH) || (IR_opcode == OPCODE_LH) || (IR_opcode == OPCODE_LHU)) begin
                        case(ByteEnableLogic)
                            (0) : byteenable <= (4'd12);                   //  Byte enable the first two bytes
                            (1) : byteenable <= (4'd0);                   //  Do nothing. This won't work
                            (2) : byteenable <= (4'd3);                  //  Byte enable the latter two bytes
                            (3) : byteenable <= (4'd0);                   //  Do nothing. This won't work
                        endcase
                        writedata = { register[IR_rt][31:16] , register[IR_rt][31:16] };
                    end
                    else if ((IR_opcode == OPCODE_SW) || (IR_opcode == OPCODE_LW)) begin
                        byteenable <= (4'd15);
                        writedata = register[IR_rt];
                    end
                    else if (IR_opcode == OPCODE_LWL) begin 
                        case(ByteEnableLogic)
                            (0) : byteenable <= (4'd15);
                            (1) : byteenable <= (4'd7);                    
                            (2) : byteenable <= (4'd3);                     
                            (3) : byteenable <= (4'd1);                    
                        endcase 
                    end
                    else if (IR_opcode == OPCODE_LWR) begin    
                        case(ByteEnableLogic)
                            (0) : byteenable <= (4'd8);                    //  Byte enable all bytes
                            (1) : byteenable <= (4'd12);                     //  Byte enable the first 3 bytes
                            (2) : byteenable <= (4'd14);                     //  Byte enable the first 2 bytes
                            (3) : byteenable <= (4'd15);                     //  Byte enable the first byte
                        endcase
                    end
                    state <= MEM;
                end
                else if (IR_opcode == 6'd0) begin //R Type instructions
                    case(IR_funct)
                        //Add, sub, mult, div
                        (FC_ADDU): ALUout <= (IR_rd != 0) ? ($unsigned(register[IR_rs]) + $unsigned(register[IR_rt])) : (32'h00);
                        (FC_SUBU): ALUout <= (IR_rd != 0) ? ($unsigned(register[IR_rs]) - $unsigned(register[IR_rt])) : (0);
                        (FC_DIV): begin
                            ALUout[63:32] <= register[IR_rs] % register[IR_rt];
                            ALUout[31:0] <= register[IR_rs] / register[IR_rt];
                        end
                        (FC_MULT):   ALUout <= ($signed(register[IR_rs]) * $signed(register[IR_rt]));
                        (FC_MULTU):  ALUout <= ($unsigned(register[IR_rs]) * $unsigned(register[IR_rt]));
                        // ALL LO hereonout
                        //Bitwise operation
                        (FC_AND):    ALUout <= (IR_rd != 0) ? (register[IR_rs] & register[IR_rt]) : (0);
                        (FC_OR):     ALUout <= (IR_rd != 0) ? (register[IR_rs] | register[IR_rt]) : (0);
                        (FC_XOR):    ALUout <= (IR_rd != 0) ? (register[IR_rs] ^ register[IR_rt]) : (0);
                        //Set operations
                        (FC_SLT):    ALUout <= ((IR_rd != 0) && ($signed(register[IR_rs]) < $signed(register[IR_rt]))) ? ({32'b1}) : ({32'b0});
                        (FC_SLTU):   ALUout <= ((IR_rd != 0) && ($unsigned(register[IR_rs]) < $unsigned(register[IR_rt]))) ? ({32'b1}) : ({32'b0});
                        //  Logical
                        (FC_SLL):    ALUout <= (IR_rd != 0) ? (register[IR_rt] << IR_shmat) : (0);
                        (FC_SLLV):   ALUout <= (IR_rd != 0) ? (register[IR_rt] << register[IR_rs]) : (0);
                        (FC_SRL):    ALUout <= (IR_rd != 0) ? (register[IR_rt] >> IR_shmat) : (0);
                        (FC_SRLV):   ALUout <= (IR_rd != 0) ? (register[IR_rt] >> register[IR_rs]) : (0);
                        //  Arithmetic
                        (FC_SRA):    ALUout <= (IR_rd != 0) ? (register[IR_rt] >>> IR_shmat) : (0);
                        (FC_SRAV):   ALUout <= (IR_rd != 0) ? (register[IR_rt] >>> register[IR_rs]) : (0);
                        //  Move instructions
                        (FC_MFHI):   ALUout <= (IR_rd != 0) ? (HI) : (0);
                        (FC_MFLO):   ALUout <= (IR_rd != 0) ? (LO) : (0);
                        (FC_MTHI):   ALUout <= (register[IR_rs]);
                        (FC_MTLO):   ALUout <= (register[IR_rs]);
                        // Jump instructions
                        //(FC_JR):    
                        (FC_JALR):  ALUout <= PC + 32'd4;
                    endcase
                    state <= WB;
                end
                else if ((IR_opcode == 6'd2) || (IR_opcode == 6'd3)) begin //JUMP Types
                    if (IR_opcode == 6'd3) register[31] <= PC + 32'd8;
                    PC_jump <= {PC_next[31:28], (IR_targetAddress << 2)};
                    PC <= PC_next;
                    state <= IF;  
                end
                else begin //immediate types
                    case(IR_opcode)
                        //  Basic Arithmetic
                        (OPCODE_ADDIU) :    ALUout <= (IR_rt != 0) ? ($unsigned(register[IR_rs]) + $unsigned(IR_address_immediate)) : (0);
                        //  Bitwise operations
                        (OPCODE_ANDI) :     ALUout <= (IR_rt != 0) ? ($unsigned(register[IR_rs]) & $unsigned(IR_address_immediate)) : (0);
                        (OPCODE_ORI) :      ALUout <= (IR_rt != 0) ? ($unsigned(register[IR_rs]) | $unsigned(IR_address_immediate)) : (0);
                        (OPCODE_XORI) :     ALUout <= (IR_rt != 0) ? ($unsigned(register[IR_rs]) ^ $unsigned(IR_address_immediate)) : (0);
                        //  Load and sets
                        (OPCODE_LUI) :      ALUout <= (IR_rt != 0) ? (IR_address_immediate << 16) : (0);
                        (OPCODE_SLTI) :     ALUout <= ((IR_rt != 0) && ($signed(register[IR_rs]) < $signed(IR_address_immediate))) ?  (1) : (0);
                        (OPCODE_SLTIU) :    ALUout <= ((IR_rt != 0) && ($unsigned(register[IR_rs]) < $unsigned(IR_address_immediate))) ? (1) : (0);
                        
                        (OPCODE_BEQ) :      PC_jump <= (register[IR_rs] == register[IR_rt]) ? (PC + 32'd4 + ({{ 16{IR_address_immediate[15]} } , IR_address_immediate} << 2)) : (0);
                        (OPCODE_BGTZ) :     PC_jump <= ($signed(register[IR_rs]) > 0) ? (PC + 32'd4 + ({{ 16{IR_address_immediate[15]} } , IR_address_immediate} << 2)) : (0);
                        (OPCODE_BNE) :      PC_jump <= (register[IR_rs] != register[IR_rt]) ? (PC + 32'd4 + ({{ 16{IR_address_immediate[15]} } , IR_address_immediate} << 2)) : (0);
                        (OPCODE_BLEZ) :     PC_jump <= ($signed(register[IR_rs]) <= 0) ? (PC + 32'd4 + ({{ 16{IR_address_immediate[15]} } , IR_address_immediate} << 2)) : (0);
                        
                        (6'd1): begin   //  Is instruction BGEZ; BGEZAL; BLTZ; BLTZAL
                            case (IR_rt)
                                (6'd1) :    PC_jump <= ($signed(register[IR_rs]) >= 0) ? (PC + 32'd4 + ({{ 16{IR_address_immediate[15]} } , IR_address_immediate} << 2)) : (0);// BGEZ
                                (6'd17) : begin //  BGEZAL
                                    PC_jump <= ($signed(register[IR_rs]) >= 0) ? (PC + 32'd4 + ({{ 16{IR_address_immediate[15]} } , IR_address_immediate} << 2)) : (0);
                                    register[31] = PC + 32'd4;
                                end
                                (6'd0) :    PC_jump <= ($signed(register[IR_rs]) < 0) ? (PC + 32'd4 + ({{ 16{IR_address_immediate[15]} } , IR_address_immediate} << 2)) : (0); // BLTZ 
                                (6'd16) : begin 
                                    PC_jump <= ($signed(register[IR_rs]) < 0) ? (PC + 32'd4 + ({{ 16{IR_address_immediate[15]} } , IR_address_immediate} << 2)) : (0); // BLTZAL
                                    register[31] <= PC + 32'd4;
                                end
                            endcase
                        end
                    endcase
                    if ((IR_opcode == 6'd1) || (IR_opcode == OPCODE_BEQ) || (IR_opcode == OPCODE_BGTZ) || (IR_opcode == OPCODE_BNE) || (IR_opcode == OPCODE_BLEZ))  begin
                        PC <= PC_next;
                        state <= IF;
                    end
                    else state <= WB;
                end
            end
            (MEM): begin 
                //Write to RAM
                if (!waitrequest) begin //FIXME: Made a change here
                    if (sOp) begin      //If store instuctions
                        PC <= PC_next;
                        state <= IF;      
                        // STORE INSTRUCTIONS END 
                    end
                    else if (lOp) begin
                        //For load, just read and move to next step.
                        state <= WB;
                    end
                    else begin
                        //No other instrucitons should be here. If so, there is an error.
                        state <= HALT;
                    end
                end
                else state <= MEM;
            end
            (WB): begin
                if (lOp) begin
                    case(IR_opcode)
                        (OPCODE_LB) : begin //SIGNED EXTENDED
                            case(ByteEnableLogic)
                                (0) : register[IR_rt] <= { readdata[31:24] , { 24{readdata[24]} } };
                                (1) : register[IR_rt] <= { readdata[23:16] , { 24{readdata[16]} } };       
                                (2) : register[IR_rt] <= { readdata[15:8] , { 24{readdata[8]} } };               
                                (3) : register[IR_rt] <= { readdata[7:0] , { 24{readdata[0]} } };                   
                            endcase
                        end
                        (OPCODE_LBU) : begin
                            case(ByteEnableLogic)
                                (0) : register[IR_rt] <= { readdata[31:24] , 24'd0 };
                                (1) : register[IR_rt] <= { readdata[23:16] , 24'd0 };       
                                (2) : register[IR_rt] <= { readdata[15:8] , 24'd0 };               
                                (3) : register[IR_rt] <= { readdata[7:0] , 24'd0 };                
                            endcase
                        end
                        (OPCODE_LH) : begin
                            case(ByteEnableLogic)
                                (0) : register[IR_rt] <= { readdata[31:16] , { 16{readdata[16]} } };
                                (2) : register[IR_rt] <= { readdata[15:0] , { 16{readdata[0]} } };
                            endcase
                        end
                        (OPCODE_LHU) : begin
                            case(ByteEnableLogic)
                                (0) : register[IR_rt] <= { readdata[31:16] , 16'd0 };
                                (2) : register[IR_rt] <= { readdata[15:0] , 16'd0 };              
                            endcase
                        end
                        (OPCODE_LW) : begin
                            register[IR_rt] <= readdata;
                        end
                        (OPCODE_LWL) : begin    //FIXME: Turn bigendian
                            case(ByteEnableLogic)
                                (0) : register[IR_rt] <= readdata;
                                (1) : register[IR_rt] <= { readdata[23:0], register[IR_rt][7:0] };     
                                (2) : register[IR_rt] <= { readdata[15:0], register[IR_rt][15:0] };            
                                (3) : register[IR_rt] <= { readdata[7:0], register[IR_rt][23:0] };                   
                            endcase
                        end
                        (OPCODE_LWR) : begin    //FIXME: Turn bigendian
                            case(ByteEnableLogic)
                                (0) : register[IR_rt] <= { register[IR_rt][31:8], readdata[31:24] };
                                (1) : register[IR_rt] <= { register[IR_rt][31:16], readdata[31:16] };     
                                (2) : register[IR_rt] <= { register[IR_rt][31:24], readdata[31:8] };            
                                (3) : register[IR_rt] <= readdata;            
                            endcase
                        end
                    endcase
                    // LOAD INSTRUCTIONS END
                end
                else if (IR_opcode == 0) begin
                    if ((IR_funct == FC_DIV) || (IR_funct == FC_MULT) || (IR_funct == FC_MULTU)) begin
                        HI <= ALUout[63:32];
                        LO <= ALUout[31:0];
                    end
                    else if ((IR_funct == FC_MTHI)) begin //Other hi/lo instructions
                        HI <= ALUout[31:0];
                    end
                    else if ((IR_funct == FC_MTLO)) begin
                        LO <= ALUout[31:0];
                    end
                    else if ((IR_funct == FC_JR) || (IR_funct == FC_JALR)) begin //Jump stuff
                        PC_jump <= register[IR_rs];
                        if (IR_funct == FC_JALR) register[IR_rd] <= ALUout[31:0];
                    end
                    else begin
                        // $display("saving to register rd: %d with data ALUoutLO %h", IR_rd, ALUoutLO);
                        register[IR_rd] <= ALUout[31:0];
                    end
                    // R TYPE INSTRUCTIONS END
                end
                else begin
                    register[IR_rt] <= ALUout[31:0];
                    // I TYPE INSTRUCTIONS END
                end
                state <= IF;
                PC <= PC_next;
            end
            (HALT): begin
                register_v0 <= (!active) ? register[2] : register_v0;
                active <= (!active) ? 0 : active;
            end
        endcase
    end

    function [31:0] reverse;
        input [31:0] endian;
        for (integer i = 0; i < 32; i++) begin
            reverse[i] = endian[31-i];
        end
    endfunction
    
    always @(*) begin
        if(state == IF) begin
            //$display("address %d", address - 3217031068);
            $display("in IF");
            //for(integer a = 0; a < 32; a++) begin
            //    $display("register %d : %h", a, register[a]);
            //end
        end
        else if(state == ID) begin
            //$display("address %d", address - 3217031068);
            //$display("readdata %d", readdata);
            //$display("IR %d", InstructionReg);
            //$display("IR opcode %d", IR_opcode);
            //$display("fn code %d", IR_funct);
            //$display("In ID lop is %d", lOp);
            //$display("In ID sop is %d", sOp);
            $display("in ID");
        end
        else if(state == EX) begin
            //$display("In EX readdata %h", readdata);
            //$display("In EX IR %h", InstructionReg);
            //$display("In EX IR opcode %d", IR_opcode);
            //$display("In EX lop is %d", lOp);
            //$display("In EX sop is %d", sOp);
            //$display("In EX byteenable is %b", byteenable);
            //$display("ALUout: %h", ALUoutLO);
            //$display("Address to write to: %d", IR_address_immediate);
            $display("in EX");
            //if (sOp == 1) begin
                //$display("SW occuring");
            //end
        end
        else if(state == MEM) begin
            //$display("ByteEnableLogic %d", ByteEnableLogic);
            //$display("read %d", read);
            //$display("write %d", write);
            //$display("writedata %d", writedata);
            //$display("In MEM byteenable is %b", byteenable);
            $display("in MEM");
        end
        else if(state == WB) begin
            //$display("read %d", read);
            //$display("write %d", write);
            //$display("In WB byteenable is %b", byteenable);
            //$display("ByteEnableLogic %d", ByteEnableLogic);
            //$display("data is: %h " , { { 16{readdata[15]} } , readdata[15:0] });
            //$display("ALUOUT %h", ALUout);
            $display("in WB");
        end
    end
    

endmodule