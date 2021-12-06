/**
 * @MIPS CPU
 * @brief:  Little Endian CPU
 * @date 2021-11-28
 *
 * @copyright Copyright (c) 2021
 *
 */

module mips_cpu_bus
(
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

//  Defined opcodes FIXME:  LWR & LWL
    /*
        Instructions (ref:https://opencores.org/projects/plasma/opcodes)
        Opcodes:
        R types have an opcode of 6d0
        J type unique opcodes
        I type uniques opcodes
    */
    typedef enum logic[5:0]
    {
        OPCODE_R = 6'd0,
        OPCODE_J = 6'd2,
        OPCODE_JAL = 6'd3,

        //  TODO:   move those 4 into a new case where differentiated by their rt
        /*OPCODE_BGEZ = 6'd51,  
        OPCODE_BGEZAL = 6'd52,
        OPCODE_BLTZ = 6'd53,  
        OPCODE_BLTZAL = 6'd54,*/

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
        OPCODE_SW = 6'd43
    } opcode_t;

//  R types are differentiated through their function code
//  States
    typedef enum logic[5:0]
    {
        FUNCTION_CODE_ADDU = 6'd33,
        FUNCTION_CODE_SUBU = 6'd35,
        FUNCTION_CODE_AND = 6'd36,
        FUNCTION_CODE_OR = 6'd37,
        FUNCTION_CODE_SLT = 6'd42,
        FUNCTION_CODE_SLTU = 6'd43,
        FUNCTION_CODE_XOR = 6'd38,
        FUNCTION_CODE_SLL = 6'd0,
        FUNCTION_CODE_SLLV = 6'd4,
        FUNCTION_CODE_SRA = 6'd3,
        FUNCTION_CODE_SRAV = 6'd7,
        FUNCTION_CODE_SRL = 6'd2,
        FUNCTION_CODE_SRLV = 6'd6,
        FUNCTION_CODE_DIV = 6'd26,
        FUNCTION_CODE_DIVU = 6'd27,
        FUNCTION_CODE_MULT = 6'd24,
        FUNCTION_CODE_MULTU = 6'd25,

        FUNCTION_CODE_MFHI = 6'd16,
        FUNCTION_CODE_MTHI = 6'd17,
        FUNCTION_CODE_MFLO = 6'd18,
        FUNCTION_CODE_MTLO = 6'd19,

        //FUNCTION_CODE_LWR = 6'd,    //FIXME:  Can't find any of the function codes for the two
        //FUNCTION_CODE_LWL = 6'd,    //FIXME:  Can't find any of the function codes for the two
        FUNCTION_CODE_JALR = 6'd9,
        FUNCTION_CODE_JR = 6'd8
    } fcode_t;

//  State
    typedef enum logic[1:0]
    {
        FETCH = 2'd0,
        EXEC1 = 2'd1,
        EXEC2 = 2'd2,
        HALT = 2'd3
    } state_t;

//  Registers
    /*
        Register formats (ref: https://www.dcc.fc.up.pt/~ricroc/aulas/1920/ac/apontamentos/P04_encoding_mips_instructions.pdf)
        Title       :       Reg #       :       Usage
        $zero       :       0           :       Constantly of value 0
        $v0-$v1     :       2, 3        :       Values for results and expression evaluation
        $a0-$v3     :       4, 7        :       Argus
        $t0-$t7     :       8, 15       :       Temps
        $t8-$t9     :       24, 25      :       More temps
        $s0-$s7     :       16, 23      :       Saved
        $gp         :       28          :       Global pointers
        $sp         :       29          :       Stack Pointer
        $fp         :       30          :       Frame pointer
        $ra         :       31          :       Return address
    */
    //  General Registers
        logic signed [31:0][31:0] register; //  This is defined as signed to emphasise operations may be unsigned
    //  Program counter registers
        logic[31:0] PC, PC_next, PC_Jump_Branch;
        logic[1:0] isJumpOrBranch;
    //  State registers
        state_t state;
    //  Instruction register
        logic[31:0] InstructionReg;
    //  Multiplication registers
        logic[31:0] HI;
        logic[31:0] LO;


//  Wire declaration
    /*
            Wires used in ALU
            |Field name: 6 bits |5 bits |5 bits |5 bits  |5 bits     |6 bits     |
            |R format:   op     |rs     |rt     |rd      |shmat      |funct      |
            |I format:   op     |rs     |rt     |address/immediate               |
            |J format:   op     |target address                                  |
    */
    //  Temporary variable
        logic signed [31:0] tempWire;
    //  Used in ALU
        logic[5:0] opcode;
        logic[4:0] rs;
        logic[4:0] rt;
        logic[4:0] rd;
        logic[4:0] shmat;
        logic[5:0] funct;
        logic[15:0] address_immediate;
        logic[25:0] targetAddress;
    //  Temporary wires
    //  Multiplication
        logic[63:0] multWire;
    //  Memory access
        logic sOp; //  Are we loading memory? Useful to differentiate
        logic lOp; //  Are we storing memory? Useful to differentiate
    //  Branch or load
        logic bOj; //  Are we branching or storing? Useful to differentiate
    //  Load stores
        logic[31:0] addressBit;
    //  Interupts
        logic stall;        //  Are we going to stall? Useful to differentiate
    //  Byteenable logic
        logic [1:0] byteEnableOutOfBound;
    //  Big Endian
        logic[31:0] littleEndian;

//  Initialising CPU
    initial begin   //  FIXME:  make me not initial
        //  Initialise register
            integer i;
            for(i = 0; i < 32; i++) begin
                register[i] = 32'b0;
            end
            HI = 32'd0;
            LO = 32'd0;
        //  Initialise interupt handles
            stall = 0;
        //  initialise state
            state = HALT;
        //  Program counter
            PC = 32'hBFC00000;                  //  Initialise PC
            PC_next = PC + 32'd4;               //  Initialise PC_next
            PC_Jump_Branch = PC_next + 32'd4;   //  Initialise PC_jump_branch
            isJumpOrBranch = 2'd0;
        //  Memory Address
            tempWire = 32'd0;
        //  Byteable logic
            byteenable = 4'b1111;
            byteEnableOutOfBound = 0;
    end

//  Automatic wire assignment
//  Instruction register
    /*
    //  Yes, this really is what you think it is. And yes, it really is there because of why you think it is. Don't judge...
        assign InstructionReg = (state == FETCH) ? ({   readdata[0], readdata[1], readdata[2], readdata[3],
                                                    readdata[4], readdata[5], readdata[6], readdata[7],
                                                    readdata[8], readdata[9], readdata[10], readdata[11],
                                                    readdata[12], readdata[13], readdata[14], readdata[15],
                                                    readdata[16], readdata[17], readdata[18], readdata[19],
                                                    readdata[20], readdata[21], readdata[22], readdata[23],
                                                    readdata[24], readdata[25], readdata[26], readdata[27],
                                                    readdata[28], readdata[29], readdata[30], readdata[31],
                                                })
                                : (InstructionReg);   //  Utilise instructionReg to keep contents up to date
    */
    assign InstructionReg = (state == FETCH) ? (readdata) : (InstructionReg);
//  ALU wires
    assign opcode = InstructionReg[31:26];
    assign funct = InstructionReg[5:0];
    assign shmat = InstructionReg[10:6];
    assign rs = InstructionReg[25:21];
    assign rt = InstructionReg[20:16];
    assign rd = InstructionReg[15:11];
    assign targetAddress = InstructionReg[25:0];
    assign address_immediate = InstructionReg[15:0];
    //  Temporary wires
        //  Multiplication
            assign multWire = ((state == EXEC1) && (opcode == OPCODE_R)) ?
                        ((funct == FUNCTION_CODE_MULT) ? 
                            (register[rs] * register[rt]) : (64'h0000)) :
                        ((funct == FUNCTION_CODE_MULTU) ? 
                            ($unsigned(register[rs]) * $unsigned(register[rt])) : (64'h0000));
//  Endian Wire
    
//  Memory access
    assign lOp = (
            (opcode == OPCODE_LB)   ||
            (opcode == OPCODE_LBU)  ||
            (opcode == OPCODE_LH)   ||
            (opcode == OPCODE_LHU)  ||
            (opcode == OPCODE_LW));

    assign sOp = (
            (opcode == OPCODE_SB)   ||
            (opcode == OPCODE_SW)   ||
            (opcode == OPCODE_SH));

    assign bOj = (
            (opcode == OPCODE_J)    ||
            (opcode == OPCODE_JAL)  ||
            (opcode == OPCODE_BEQ)  ||
            (opcode == OPCODE_BGTZ) ||
            (opcode == OPCODE_BNE)  ||
            (opcode == OPCODE_BLEZ) ||
            (opcode == 6'd1));
            
//  Combinatorial block FIXME:  What the fuck

    always_comb begin
        case (state)
            (FETCH) : begin
                //Address is set to program counter, which requires read to be set to 1
                    address = PC;
                //  Read/Write declarations defined within
                    read = 1;
                    write = 0;
                //  Byte enable specified
                    byteenable = 4'b1111;
            end
            (EXEC1 || EXEC2) : begin //  Specific operations, depending on if load or store Specific operations, depending on if load or store
                    byteenable = 4'b1111;
                    case((register[rs] + address_immediate) % 4)  //  Define byteEnableOutOfBounds for load in EXEC2 and store in EXEC1
                        (0): byteEnableOutOfBound = 2'd0;
                        (1): byteEnableOutOfBound = 2'd1;
                        (2): byteEnableOutOfBound = 2'd2;
                        (3): byteEnableOutOfBound = 2'd3;
                    endcase

                    if (sOp) begin
                        read = 0;
                        write = 1;
            end
            (HALT) : begin
                read = 0;
                write = 0;
            end
        endcase
    end


//  Clocked block   <-  Where instructions are orchestrated
    always_ff @(posedge clk) begin
        if(reset) begin
            state <= FETCH;
            active <= 1;
            address <= 32'hBFC00000;
            for(integer i = 0; i < 32; i++) begin
                register[i] <= 32'h0;
            end
        end
        case (state)
            (FETCH) : begin
                //  If we enter halt state
                if (address == 32'd0) begin
                    state <= HALT;
                end
                //  General case
                else begin
                    address = PC;
                    read <= 1;
                    write <= 0;
                    PC_next <= PC + 32'd4;
                    PC_Jump_Branch <= PC_next + 32'd4;
                    state <= (waitrequest) ? (FETCH) : (EXEC1);
                    isJumpOrBranch <= (isJumpOrBranch == 2'd1) ? (2'd2) : (2'd1); //TODO: Branch to branch?
                    isJumpOrBranch <= (bOj) ? (2'd1) : (2'd0);

                    byteenable <= 4'b1111;
                end
            end
            (EXEC1) : begin
                //  Instructions:   (ref: https://uweb.engr.arizona.edu/~ece369/Resources/spim/MIPSReference.pdf)
                case(opcode)
                    //  R type instructions
                        (OPCODE_R): begin
                            //  We have to determine what the R type instruction is by virtue of its function code
                            case(funct)
                            //  Basic arithematic
                                (FUNCTION_CODE_ADDU): register[rd] <= (rd != 0) ? ($unsigned(register[rs]) + $unsigned(register[rt])) : (32'h00);
                                (FUNCTION_CODE_SUBU): register[rd] <= (rd != 0) ? ($unsigned(register[rs]) - $unsigned(register[rt])) : (0);
                                (FUNCTION_CODE_DIV): begin
                                        HI <= register[rs] % register[rt];
                                        LO <= register[rs] / register[rt];
                                end
                                (FUNCTION_CODE_DIVU): begin 
                                        HI <= $unsigned(register[rs]) % $unsigned(register[rt]);
                                        LO <= $unsigned(register[rs]) / $unsigned(register[rt]);
                                end
                                (FUNCTION_CODE_MULT): begin
                                    HI <= multWire[63:32];
                                    LO <= multWire[31:0];
                                end
                                (FUNCTION_CODE_MULTU): begin
                                    HI <= multWire[63:32];
                                    LO <= multWire[31:0];
                                end

                            //  Bitwise operation
                                (FUNCTION_CODE_AND):        register[rd] <= (rd != 0) ? (register[rs] & register[rt]) : (0);
                                (FUNCTION_CODE_OR):         register[rd] <= (rd != 0) ? (register[rs] | register[rt]) : (0);
                                (FUNCTION_CODE_XOR):        register[rd] <= (rd != 0) ? (register[rs] ^ register[rt]) : (0);
                            //  Set operations
                                (FUNCTION_CODE_SLT):        register[rd] <= ((rd != 0) && (register[rs] < register[rt])) ? ({32'b1}) : ({32'b0});
                                (FUNCTION_CODE_SLTU):       register[rd] <= ((rd != 0) && ($unsigned(register[rs]) < $unsigned(register[rt]))) ? ({32'b1}) : ({32'b0});

                                //  Logical
                                    (FUNCTION_CODE_SLL):    register[rd] <= (rd != 0) ? (register[rt] << shmat) : (0);
                                    (FUNCTION_CODE_SRL):    register[rd] <= (rd != 0) ? (register[rt] >>> shmat) : (0);
                                    (FUNCTION_CODE_SLLV):   register[rd] <= (rd != 0) ? (register[rt] << register[rs]) : (0);
                                    (FUNCTION_CODE_SRLV):   register[rd] <= (rd != 0) ? (register[rt] >>> register[shmat]) : (0);
                                //  Arithmetic
                                    (FUNCTION_CODE_SRA):    register[rd] <= (rd != 0) ? (register[rt] >>> shmat) : (0);
                                    (FUNCTION_CODE_SRAV):   register[rd] <= (rd != 0) ? (register[rt] >>> register[rs]) : (0);
                            //  Move instructions
                                (FUNCTION_CODE_MFHI):   register[rd] <= (rd != 0) ? (HI) : (0);
                                (FUNCTION_CODE_MFLO):   register[rd] <= (rd != 0) ? (LO) : (0);
                                (FUNCTION_CODE_MTHI):   HI <= (register[rs]);
                                (FUNCTION_CODE_MTLO):   LO <= (register[rs]);
                            endcase
                        end

                    //  J type instructions
                        (OPCODE_J): PC_Jump_Branch <= {8'b0, targetAddress};
                        (OPCODE_JAL) : begin
                            register[31] <= PC + 5'd4;
                            PC_Jump_Branch <= {8'b0, targetAddress};
                        end

                    //  I type instructions
                        //  Basic Arithmetic
                            (OPCODE_ADDIU) :    register[rt] <= (rt != 0) ? ($unsigned(register[rs]) + $unsigned(address_immediate)) : (0);
                        //  Bitwise operations
                            (OPCODE_ANDI) :     register[rt] <= (rt != 0) ? ($unsigned(register[rs]) & $unsigned(address_immediate)) : (0);
                            (OPCODE_ORI) :      register[rt] <= (rt != 0) ? ($unsigned(register[rs]) | $unsigned(address_immediate)) : (0);
                            (OPCODE_XORI) :     register[rt] <= (rt != 0) ? ($unsigned(register[rs]) ^ $unsigned(address_immediate)) : (0);
                        //  Load and sets
                            (OPCODE_LUI) :      register[rt] <= (rt != 0) ? (address_immediate << 16) : (0);
                            (OPCODE_SLTI) :     register[rt] <= ((rt != 0) && (register[rs] < $signed(address_immediate))) ?  (1) : (0);
                            (OPCODE_SLTIU) :    register[rt] <= ((rt != 0) && ($unsigned(register[rs]) < $unsigned(address_immediate))) ? (1) : (0);
                        //  Branch
                            //  Share opcode
                                (6'd1): begin   //  Is instruction BGEZ; BGEZAL; BLTZ; BLTZAL
                                    case (rt)
                                        //  BGEZ    TODO:   Check I need to be implemented
                                        (6'd1) :    PC_Jump_Branch <= (register[rs] >= 0) ? (PC + (address_immediate << 2)) : (PC_next + 32'd4);
                                        //  BGEZAL  TODO:   Check I need to be implemented
                                        (6'd17) : begin 
                                            PC_Jump_Branch <= (register[rs] >= 0) ? (PC + (address_immediate << 2)) : (PC_next + 32'd4);
                                            register[31] = PC;
                                        end
                                        //  BLTZ
                                        (6'd0) :    PC_Jump_Branch <= (register[rs] < 0) ? (PC + (address_immediate << 2)) : (PC_next + 32'd4);
                                        //  BLTZAL
                                        (6'd16) : begin 
                                            PC_Jump_Branch <= (register[rs] < 0) ? (PC + (address_immediate << 2)) : (PC_next + 32'd4);
                                            register[31] <= PC;
                                        end
                                    endcase
                                end

                            //  Rest
                                (OPCODE_BEQ) :  PC_Jump_Branch <= (register[rs] == register[rt]) ? (PC + (address_immediate << 2)) : (PC_next + 32'd4);
                                (OPCODE_BGTZ) : PC_Jump_Branch <= (register[rs] > 0) ? (PC + (address_immediate << 2)) : (PC_next + 32'd4);
                                (OPCODE_BNE) :  PC_Jump_Branch <= (register[rs] != register[rt]) ? (PC + (address_immediate << 2)) : (PC_next + 32'd4);
                                (OPCODE_BLEZ) : PC_Jump_Branch <= (register[rs] <= 0) ? (PC + (address_immediate << 2)) : (PC_next + 32'd4);


                        //  Store
                                (OPCODE_SB) : begin
                                    /*  Write must be high
                                        setting values ton writedata
                                        byte enable will be us choosing byte at address
                                        Address is determined @ exec1
                                    */
                                    write <= 1;  //  Enable write so that memory can be written upon
                                    read <= 0;
                                    tempWire = register[rt];
                                    case(byteEnableOutOfBound)
                                        (0) : begin
                                            byteenable <= (4'd1);    //  Byte enable the first byte
                                            writedata <= {24'd0, tempWire[7:0]};
                                        end
                                        (1) : begin
                                            byteenable <= (4'd2);    //  Byte enable the second byte
                                            writedata <= {16'd0, tempWire[15:8], 8'd0};
                                        end
                                        (2) : begin
                                            byteenable <= (4'd4);    //  Byte enable the third byte
                                            writedata <= {8'd0, tempWire[23:16], 16'd0};
                                        end
                                        (3) : begin
                                            byteenable <= (4'd8);    //  Byte enable the fourth byte
                                            writedata <= {tempWire[31:24], 24'd0};
                                        end
                                    endcase
                                end
                                (OPCODE_SH) : begin
                                    write <= 1;  //  Enable write so that memory can be written upon
                                    read <= 0;
                                    case(byteEnableOutOfBound)
                                        (0) : begin
                                            byteenable <= (4'd3);    //  Byte enable the first two bytes
                                            writedata = {16'd0, tempWire[15:0]};
                                        end
                                        (1 || 3) : byteenable <= (4'd0);   //  Do nothing. This won't work
                                        (2) : begin
                                            byteenable <= (4'd12);   //  Byte anable the latter two bytes
                                            writedata = {tempWire[15:0], 16'd0};
                                        end
                                    endcase
                                end
                                (OPCODE_SW) : begin
                                    if(byteEnableOutOfBound == 0) begin
                                        byteenable <= 4'd15;           //  Byte enable all bytes
                                    end
                                    else begin
                                        byteenable <= 4'd0;         //  Not wrote
                                    end
                                    write <= 1;                  //  Enable write so that memory can be written upon
                                    read <= 0;
                                    writedata <= tempWire;   //  Write
                                    address <= (register[rs] + address_immediate);
                                end
                endcase
                //  Load
                    if(lOp) begin
                        read <= 1;
                        address <= (OPCODE_LBU || OPCODE_LHU) ? 
                            (register[rs] + $unsigned(address_immediate)) : 
                            ($signed(register[rs]) + ({{16{address_immediate[15]}}, address_immediate}));
                        case (opcode)
                            (OPCODE_LB || OPCODE_LBU) : begin
                                case(byteEnableOutOfBound)
                                    (0):        byteenable <= 4'b0001;
                                    (1):        byteenable <= 4'b0010;
                                    (2):        byteenable <= 4'b0100;
                                    (3):        byteenable <= 4'b1000;
                                endcase
                            end
                            (OPCODE_LH || OPCODE_LHU) : begin
                                case(byteEnableOutOfBound)
                                    (0):        byteenable <= 4'b0011;
                                    (1 || 3):   byteenable <= 4'b0000;
                                    (2):        byteenable <= 4'b1100;
                                endcase
                            end
                            (OPCODE_LW) : begin
                                case(byteEnableOutOfBound)
                                    (0):            byteenable <= 4'b1111;
                                    (1 || 2 || 3):  byteenable <= 4'd0000;
                                endcase
                            end
                        endcase
                    end
                //  Setting up for next state/stalls
                    state <= (!lOp) ? (FETCH) : (EXEC2);        //  Is it not a store operation?
                    //state <= (waitrequest && (lOp || sOp)) ? (EXEC1) : (state);   //  TODO:   RE-ADD ME
                    // TODO: Add if statement to implement waitrequest.
                    PC <= (!lOp) ? (PC_next) : (PC);
                    if(isJumpOrBranch == 2'd2) begin
                        PC <= PC_Jump_Branch;
                        isJumpOrBranch <= 0;
                    end
            end
            (EXEC2) : begin
                //  Resetting read
                    read <= 0;
                //  Load https://inst.eecs.berkeley.edu/~cs61c/resources/MIPS_help.html
                    case(opcode)
                            (OPCODE_LB) : begin
                                //  Load in the nth byte from the RAMs input to the CPU
                                //  Determine if latter 24 bits are 0 or 1
                                //  ((readdata[7]) ? (24'hFFF): (24'h0))    TODO:   Maybe reinsert!
                                case(byteenable)
                                    (0):    begin
                                        byteenable <= 4'b0001;
                                        register[rt] <= {((readdata[7])  ? (24'hFFF): (24'h0)), readdata[7:0]};
                                    end
                                    (1):    begin
                                        byteenable <= 4'b0010;
                                        register[rt] <= {((readdata[15]) ? (24'hFFF): (24'h0)), readdata[15:8]};
                                    end
                                    (2):    begin
                                        byteenable <= 4'b0100;
                                        register[rt] <= {((readdata[23]) ? (24'hFFF): (24'h0)), readdata[23:16]};
                                    end
                                    (3):    begin
                                        byteenable <= 4'b1000;
                                        register[rt] <= {((readdata[31]) ? (24'hFFF): (24'h0)), readdata[31:24]};
                                    end
                                endcase
                            end
                            (OPCODE_LBU) : begin
                                case(byteenable)
                                    (0):    begin
                                        byteenable <= 4'b0001;
                                        register[rt] <= {24'b0, readdata[7:0]};
                                    end
                                    (1):    begin
                                        byteenable <= 4'b0010;
                                        register[rt] <= {24'b0, readdata[15:8]};
                                    end
                                    (2):    begin
                                        byteenable <= 4'b0100;
                                        register[rt] <= {24'b0, readdata[23:16]};
                                    end
                                    (3):    begin
                                        byteenable <= 4'b1000;
                                        register[rt] <= {24'b0, readdata[31:24
                                        ]};
                                    end
                                endcase
                            end
                            (OPCODE_LH) : begin
                                case(byteenable)
                                    (0): begin
                                        byteenable <= 4'b0011;
                                        register[rt] <= {((readdata[15]) ? (16'hFF): (16'h0)), readdata[15:0]};
                                    end
                                    (1): begin
                                        byteenable <= 4'b1100;
                                        register[rt] <= {((readdata[31]) ? (16'hFF): (16'h0)), readdata[31:16]};
                                    end
                                    (2 || 3): begin
                                        byteenable <= 4'b0000;
                                        register[rt] <= register[rt];
                                    end
                                endcase
                            end
                            (OPCODE_LHU) : begin
                                case(byteenable)
                                    (0):        begin
                                        byteenable <= 4'b0011;
                                        register[rt] <= {16'b0, readdata[15:0]};
                                    end
                                    (1):        begin
                                        byteenable <= 4'b1100;
                                        register[rt] <= {16'b0, readdata[31:16]};
                                    end
                                    (2 || 3):   begin
                                        byteenable <= 4'b0000;
                                        register[rt] <= register[rt];
                                    end
                                endcase
                            end
                            (OPCODE_LW) :  begin
                                if((byteEnableOutOfBound == 2'd0) && (byteenable == 4'd15)) begin
                                    register[rt] <= readdata;
                                end
                            end
                    endcase
                //  Next state
                    PC <= (isJumpOrBranch == 2'd2) ? (PC_Jump_Branch) : (PC_next);
                    isJumpOrBranch <= (isJumpOrBranch == 2'd2) ? (2'd0) : (isJumpOrBranch);
                    state <= (FETCH);
                    byteenable <= 4'b1111;
            end
            (HALT) : begin
                read <= 0;
                write <= 0;
                active <= 0;
                if (!waitrequest) begin
                    state <= FETCH; //  Might accidentally execute something if EXEC2 so set to FETCH?
                end
            end
        endcase
    end
//  always block. Exclusively for testing! TODO:    DELET when not using
        always @(posedge clk) begin
            if (state == EXEC1)  begin

                $display("BEOOB\t%d\n", byteEnableOutOfBound);
                for(integer a = 0; (a < 32) && (opcode != 0); a++) begin
                    //$display("Register %d:\t%d\n", a, register[a]);
                    //$display("write data %d:\t", writedata);
                end
            end
        end

            //$display("LO:\t%d", LO);
            //$display("HI:\t%d", HI);
    //    end
endmodule