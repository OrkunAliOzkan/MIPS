/**
 * @MIPS CPU
 * @brief:  Implementing a clean CPU with Avalon timing put into consideration
 * @version 0.1
 * @date 2021-11-28
 *
 * @copyright Copyright (c) 2021
    FIXME:  Make BIG endian
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
        OPCODE_BGEZ = 6'd51,  //FIXME:    Need to differentiate by RT; Changed from 6'd1 <-  rt of 1
        OPCODE_BGEZAL = 6'd52,//FIXME:    Need to differentiate by RT; Changed from 6'd1 <-  rt of 17
        OPCODE_BLTZ = 6'd53,  //FIXME:    Need to differentiate by RT; Changed from 6'd1 <-  rt of 0
        OPCODE_BLTZAL = 6'd54,//FIXME:    Need to differentiate by RT; Changed from 6'd1 <-  rt of 16

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
        opcode_t opcode;
        logic[4:0] rs;
        logic[4:0] rt;
        logic[4:0] rd;
        logic[4:0] shmat;
        fcode_t funct;
        logic[15:0] address_immediate;
        logic[25:0] targetAddress;
    //  Temporary wires
    //  Multiplication
        /*  x2 32bit values multiplied make 64bit soln.
            Depending on which multiply instruction it is, we shall set to different values.
        */
        logic[63:0] multWire;
        logic[31:0] temp;  //  Used for iterative multiplication and division
    //  Memory access
        logic sOp; //  Are we loading memory? Useful to differentiate
        logic lOp; //  Are we storing memory? Useful to differentiate
    //  Branch or load
        logic bOj; //  Are we branching or storing? Useful to differentiate
    //  Load stores
        logic[31:0] addressBit;
    //  Interupts
        logic stall;        //  Are we going to stall? Useful to differentiate
        logic multing;      //  Are we still multiplying?
    //  Byteenable logic
        logic [1:0] byteEnableOutOfBound;


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
            multing = 0;
        //  Program counter
            PC = 32'hBFC00000;                  //  Initialise PC
            PC_next = PC + 32'd4;               //  Initialise PC_next
            PC_Jump_Branch = PC_next + 32'd4;   //  Initialise PC_jump_branch
            isJumpOrBranch = 2'd0;
        //  Memory Address
            tempWire = 32'd0;
        //  Byteable logic
            byteenable = 1111;
            byteEnableOutOfBound = 0;
    end

//  Automatic wire assignment
//  Instruction register
    assign InstructionReg = (state == FETCH) ? (readdata) : (InstructionReg);   //  Utilise instructionReg to keep contents up to date
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
            /*
                assign multWire = ((state == EXEC1) && (opcode == OPCODE_R)) ?
                            ((funct == FUNCTION_CODE_MULT) ? 
                                (register[rs] * register[rt]) : (64'h0000)) :
                            ((funct == FUNCTION_CODE_MULTU) ? 
                                ($unsigned(register[rs]) * $unsigned(register[rt])) : (64'h0000));
            */
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
            
        //  Jump or Branch

//  Combinatorial block TODO:   Not implemented!
    always_comb begin
        case (state)
            (FETCH) : begin
                //Address is set to program counter, which requires read to be set to 1
                read = 1;
                write = 0;
                address = PC;
                //  When do we multiply?
                    /*
                    if((opcode == FUNCTION_CODE_MULT) || (opcode == FUNCTION_CODE_MULT)) begin
                        multing = 1;
                        temp = register[rs];
                    end
                    */
            end
            (EXEC1) : begin //  Specific operations, depending on if load or store
            end
            (EXEC2) : begin //  Specific operations, depending on if load or store
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
                register[i] <= 32'h00;
            end
            byteenable <= 1111;
            case((register[rs] + address_immediate) % 4)  //  Define byteEnableOutOfBounds for load in EXEC2 and store in EXEC1
                (0): byteEnableOutOfBound <= 2'd0;
                (1): byteEnableOutOfBound <= 2'd1;
                (2): byteEnableOutOfBound <= 2'd2;
                (3): byteEnableOutOfBound <= 2'd3;
            endcase
        end
        case (state)
            (FETCH) : begin
                //  If we enter halt state
                if (address == 32'd0) begin
                    state <= HALT;
                end
                //  General case
                else begin
                    read = 1;
                    write = 0;
                    PC_next <= PC + 32'd4;
                    PC_Jump_Branch <= PC_next + 32'd4;
                    address = PC;
                    state <= (waitrequest) ? (FETCH) : (EXEC1);
                    isJumpOrBranch <= (isJumpOrBranch == 2'd1) ? (2'd2) : (2'd1); //TODO: Branch to branch?
                    isJumpOrBranch <= (bOj) ? (2'd1) : (2'd0);

                    byteenable = 1111;
                    byteEnableOutOfBound = 0;
                end
            end
            (EXEC1) : begin
                //  Instructions:   (ref: https://uweb.engr.arizona.edu/~ece369/Resources/spim/MIPSReference.pdf)
                case(opcode)
                    //  R type instructions
                        (OPCODE_R): begin
                            //  We have to determine what the R type instruction is by virtue of its function code
                            case(funct)
                            //  Basic arithematic   <-  FIXME:  MULT AND DIV need to be implemented properly
                                    (FUNCTION_CODE_ADDU): register[rd] <= (rd != 0) ? ($unsigned(register[rs]) + $unsigned(register[rt])) : (32'h00);

                                    (FUNCTION_CODE_SUBU): register[rd] <= (rd != 0) ? ($unsigned(register[rs]) - $unsigned(register[rt])) : (0);

                                    (FUNCTION_CODE_DIV): begin  //  TODO:   Possibly not implemented fully
                                        HI <= register[rs] % register[rt];
                                        LO <= register[rs] / register[rt];
                                    end

                                    (FUNCTION_CODE_DIVU): begin //  TODO:   Possibly not implemented fully
                                        HI <= $unsigned(register[rs]) % $unsigned(register[rt]);
                                        LO <= $unsigned(register[rs]) / $unsigned(register[rt]);
                                    end


                                    (FUNCTION_CODE_MULT): begin //  FIXME:  not functional!
                                        /*
                                        if(multing) begin
                                            multWire <= ((temp == 1'b1) ? (multWire + (register[rt] << count)) : (multWire)); //  FIXME:  Error
                                            temp >> 1;
                                        end

                                        if(!multing) begin
                                            HI <= multWire[63:32];
                                            LO <=  multWire[31:0];
                                            count = 0;
                                        end
                                        */
                                    end


                                    (FUNCTION_CODE_MULTU): begin //  FIXME:  not functional!
                                        /*
                                        if(multing) begin
                                            multWire += (register[rs] && 1) ? ($unsigned(register[rt]) << count) : (64'd0);  //  FIXME:  Error
                                            count++;
                                        end

                                        if(!multing) begin
                                            HI <= multWire[63:32];
                                            LO <=  multWire[31:0];
                                            count = 0;
                                        end
                                        */
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
                                        //  BGTL
                                        (6'd1) :    PC_Jump_Branch <= (register[rs] >= 0) ? (PC + (address_immediate << 2)) : (PC_next + 5'd4);

                                        //  BGTLAL
                                        (6'd17) : begin 
                                            PC_Jump_Branch <= (register[rs] >= 0) ? (PC + (address_immediate << 2)) : (PC_next + 5'd4);
                                            register[31] = PC;
                                        end

                                        //  BLTZ
                                        (6'd0) :    PC_Jump_Branch <= (register[rs] < 0) ? (PC + (address_immediate << 2)) : (PC_next + 5'd4);

                                        //  BLTZAL
                                        (6'd16) : begin 
                                            PC_Jump_Branch <= (register[rs] < 0) ? (PC + (address_immediate << 2)) : (PC_next + 5'd4);
                                            register[31] <= PC;
                                        end
                                    endcase
                                end

                            //  Rest
                                (OPCODE_BEQ) :  PC_Jump_Branch <= (register[rs] == register[rt]) ? (PC + (address_immediate << 2)) : (PC_next + 5'd4);

                                (OPCODE_BGTZ) : PC_Jump_Branch <= (register[rs] > 0) ? (PC + (address_immediate << 2)) : (PC_next + 5'd4);

                                (OPCODE_BNE) :  PC_Jump_Branch <= (register[rs] != register[rt]) ? (PC + (address_immediate << 2)) : (PC_next + 5'd4);

                                (OPCODE_BLEZ) : PC_Jump_Branch <= (register[rs] <= 0) ? (PC + (address_immediate << 2)) : (PC_next + 5'd4);


                        //  Store   FIXME:  Not operational.
                                (OPCODE_SB) : begin
                                    /*  Write must be high
                                        setting values ton writedata
                                        byte enable will be us choosing byte at address
                                        Address is determined @ exec1
                                    */
                                    write = 1;  //  Enable write so that memory can be written upon
                                    tempWire = register[rt];
                                    case(byteEnableOutOfBound)
                                        (0) : byteenable <= (4'd1);    //  Byte enable the first byte
                                        (1) : byteenable <= (4'd2);    //  Byte enable the second byte
                                        (2) : byteenable <= (4'd4);    //  Byte enable the third byte
                                        (3) : byteenable <= (4'd8);    //  Byte enable the fourth byte
                                    endcase
                                    writedata <= {24'd0, tempWire[7:0]};   //  FIXME:   Error
                                end

                                (OPCODE_SH) : begin
                                    write = 1;  //  Enable write so that memory can be written upon
                                    case(byteEnableOutOfBound)
                                        (0) : byteenable <= (4'd3);    //  Byte enable the first two bytes
                                        (1) : byteenable <= (4'd0);   //  Do nothing. This won't work
                                        (2) : byteenable <= (4'd12);   //  Byte anable the latter two bytes
                                        (3) : byteenable <= (4'd0);       //  Do nothing. This won't work
                                    endcase
                                    writedata = {16'd0, tempWire[15:0]};   //  FIXME:   Error
                                end

                                (OPCODE_SW) : begin
                                    if(byteEnableOutOfBound == 0)   byteenable <= 4'd15;           //  Byte enable all bytes
                                    else                            byteenable <= 4'd0;         //  Not wrote
                                    write <= 1;                  //  Enable write so that memory can be written upon
                                    writedata <= register[rt];   //  Write
                                    address <= (register[rs] + address_immediate);
                                end
                endcase
                //  Load
                    if(lOp) begin
                        read <= 1;
                        address <= (OPCODE_LBU || OPCODE_LHU) ? (register[rs] + $signed(address_immediate)) : ($unsigned(register[rs]) + {16'b0, address_immediate});
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
                    //state <= (!multing) ? (EXEC1) : (state);    //  Has multiplication finished?  FIXME:  Problematic
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
                                    (0):    register[rt] <= {((readdata[7])  ? (24'hFFF): (24'h0)), readdata[7:0]};
                                    (1):    register[rt] <= {((readdata[15]) ? (24'hFFF): (24'h0)), readdata[15:8]};
                                    (2):    register[rt] <= {((readdata[23]) ? (24'hFFF): (24'h0)), readdata[23:16]};
                                    (3):    register[rt] <= {((readdata[31]) ? (24'hFFF): (24'h0)), readdata[31:24]};
                                endcase
                            end

                            (OPCODE_LBU) : begin
                                case(byteenable)
                                    (0):    register[rt] <= {24'b0, readdata[7:0]};
                                    (1):    register[rt] <= {24'b0, readdata[15:8]};
                                    (2):    register[rt] <= {24'b0, readdata[23:16]};
                                    (3):    register[rt] <= {24'b0, readdata[31:24]};
                                endcase
                            end

                            (OPCODE_LH) : begin
                                case(byteenable)
                                    (0):        register[rt] <= {((readdata[15]) ? (16'hFF): (16'h0)), readdata[15:0]};
                                    (1):        register[rt] <= {((readdata[31]) ? (16'hFF): (16'h0)), readdata[31:16]};
                                    (2 || 3):  register[rt] <= register[rt];
                                endcase
                            end

                            (OPCODE_LHU) : begin
                                case(byteenable)
                                    (0):        register[rt] <= {16'b0, readdata[15:0]};
                                    (1):        register[rt] <= {16'b0, readdata[31:16]};
                                    (2 || 3):   register[rt] <= register[rt];
                                endcase
                            end

                            (OPCODE_LW) :  if(byteenable == 15) register[rt] <= readdata;
                    endcase
                //  Next state
                    PC <= (isJumpOrBranch == 2'd2) ? (PC_Jump_Branch) : (PC_next);
                    isJumpOrBranch <= (isJumpOrBranch == 2'd2) ? (2'd0) : (isJumpOrBranch);
                    state <= (FETCH);
                    byteenable <= 4'b1111;
            end
            (HALT) : begin
                active <= 0;
                if (!waitrequest) begin
                    state <= FETCH; //  Might accidentally execute something if EXEC2 so set to FETCH?
                end
            end
        endcase
    end
//  always block. Exclusively for testing! TODO:    DELET when not using
    /*
        always @(posedge clk) begin
            if (state == FETCH) begin
                for(integer a = 0; a < 32; a++) begin
                    $display("Register %d:\t%d", a, register[a]);
                end
            end

            //$display("LO:\t%d", LO);
            //$display("HI:\t%d", HI);
        end
    */
endmodule