/**
 * @MIPS CPU
 * @brief:  Implementing a clean CPU with Avalon timing put into consideration
 * @version 0.1
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
        
        FUNCTION_CODE_MTHI = 6'd17,
        FUNCTION_CODE_MTLO = 6'd19,
        FUNCTION_CODE_MFHI = 6'd16,
        FUNCTION_CODE_MFLO = 6'd18,
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
    //  Program counter registers
        logic[31:0] PC, PC_next;
    //  State registers
        state_t state;
    //  Instruction register
        logic[31:0] InstructionReg;
    //  General Registers
        logic [31:0][31:0] register; //  This is defined as signed to emphasise operations may be unsigned
    //  Multiplication registers
        logic[31:0] HI;
        logic[31:0] LO;

/*
        Wires used in ALU
        |Field name: 6 bits |5 bits |5 bits |5 bits  |5 bits     |6 bits     |
        |R format:   op     |rs     |rt     |rd      |shmat      |funct      |
        |I format:   op     |rs     |rt     |address/immediate               |
        |J format:   op     |target address                                  |
*/
//  Wire declaration
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
            //  Temporary variable
                logic[31:0] tempStoreReg;
        //  Interupts
            logic stall;        //  Are we going to stall? Useful to differentiate
            logic multing;      //  Are we still multiplying?

//  Initialising CPU
    initial begin
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
            PC = 32'hBFC00000;   //  Initialise the PC
        //  Memory Address
            tempStoreReg = 32'd0;
    end

//  Automatic wire assignment
    //  Instruction register
        assign InstructionReg = (state == FETCH) ? (readdata) : (InstructionReg);   //  Utilise instructionReg to keep contents up to date
    //  ALU wires
        assign opcode = InstructionReg[31:26];
        assign funct = InstructionReg[5:0];
        assign shmat = InstructionReg[10:6];
        assign rs = InstructionReg[20:16];
        assign rt = InstructionReg[15:11];
        assign rd = InstructionReg[25:21];
        assign targetAddress = InstructionReg[25:0];
        assign address_immediate = InstructionReg[15:0];
    //  Temporary wires
        /*
            assign multWire = ((state == EXEC1) && (opcode == OPCODE_R)) ?
                        ((funct == FUNCTION_CODE_MULT) ? 
                            (register[rs] * register[rt]) : (64'h0000)) :
                        ((funct == FUNCTION_CODE_MULTU) ? 
                            ($unsigned(register[rs]) * $unsigned(register[rt])) : (64'h0000));
        */
        //  Memory access
            assign lOp = ((
                    (opcode == OPCODE_LB)   ||
                    (opcode == OPCODE_LBU)  ||
                    (opcode == OPCODE_LH)   ||
                    (opcode == OPCODE_LHU)  ||
                    (opcode == OPCODE_LW)));
            assign sOp = ((
                    (opcode == OPCODE_SB)   ||
                    (opcode == OPCODE_SW)   ||
                    (opcode == OPCODE_SH)));

//  Combinatorial block TODO:   Not implemented!
    always_comb begin
        case (state)
            (FETCH) : begin
                /*
                    Address is set to program counter, which requires read to be set to 1
                */
                read = 1;
                read = 0;
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
            address = 32'hBFC00000;
            for(integer i = 0; i < 32; i++) begin
                register[i] <= 32'h00;
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
                    read = 1;
                    write = 0;
                    PC_next <= PC + 32'd4;
                    address = PC;
                    state <= (waitrequest) ? (FETCH) : (EXEC1);
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
                                    (FUNCTION_CODE_ADDU): begin
                                        /*
                                            We can conduct register addition with anything except for 
                                            destination being $zero, so use a multiplexer to make this
                                        */
                                        register[rd] <= (rd != 0) ? ($unsigned(register[rs]) + $unsigned(register[rt])) : (32'h00);
                                    end

                                    (FUNCTION_CODE_SUBU): begin
                                        /*
                                            Like addition, use a multiplexer to confirm rd is not $zero
                                        */
                                        register[rd] <= (rd != 0) ? ($unsigned(register[rs]) - $unsigned(register[rt])) : (0);
                                    end

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
                                    (FUNCTION_CODE_AND): begin
                                        register[rd] <= (rd != 0) ? (register[rs] & register[rt]) : (0);
                                    end

                                    (FUNCTION_CODE_OR): begin
                                        register[rd] <= (rd != 0) ? (register[rs] | register[rt]) : (0);
                                    end

                                    (FUNCTION_CODE_XOR): begin
                                        register[rd] <= (rd != 0) ? (register[rs] ^ register[rt]) : (0);
                                    end

                            //  Set operations
                                (FUNCTION_CODE_SLT): begin
                                    register[rd] <= ((rd != 0) && (register[rs] < register[rt])) ? ({32'b1}) : ({32'b0});
                                end

                                (FUNCTION_CODE_SLTU): begin
                                    register[rd] <= ((rd != 0) && ($unsigned(register[rs]) < $unsigned(register[rt]))) ? ({32'b1}) : ({32'b0});
                                end

                                //  Logical
                                    (FUNCTION_CODE_SLL): begin
                                            register[rd] <= (rd != 0) ? (register[rs] << shmat) : (0);
                                    end

                                    (FUNCTION_CODE_SRL): begin
                                            register[rd] <= (rd != 0) ? (register[rs] >>> shmat) : (0);
                                    end

                                    (FUNCTION_CODE_SLLV): begin
                                            register[rd] <= (rd != 0) ? (register[rt] << register[rs]) : (0);
                                    end

                                    (FUNCTION_CODE_SRLV): begin
                                            register[rd] <= (rd != 0) ? (register[rs] >>> register[shmat]) : (0);
                                    end
                                //  Arithmetic
                                    (FUNCTION_CODE_SRA): begin
                                            register[rd] <= (rd != 0) ? (register[rs] >>> shmat) : (0);
                                    end

                                    (FUNCTION_CODE_SRAV): begin
                                            register[rd] <= (rd != 0) ? (register[rt] >>> register[rs]) : (0);
                                    end

                            //  Move instructions
                                (FUNCTION_CODE_MFHI): begin
                                    register[rd] <= (rd != 0) ? (HI) : (0);
                                end

                                (FUNCTION_CODE_MFLO): begin
                                    register[rd] <= (rd != 0) ? (LO) : (0);
                                end
                                (FUNCTION_CODE_MTHI): begin
                                    HI <= (register[rd]);
                                end

                                (FUNCTION_CODE_MTLO): begin
                                    LO <= (register[rd]);
                                end
                            endcase
                        end

                    //  J type instructions
                        (OPCODE_J): begin
                            PC_next <= {8'b0, targetAddress};
                        end

                        (OPCODE_JAL) : begin
                            register[31] <= PC + 5'd4;
                            PC_next <= {8'b0, targetAddress};
                        end

                    //  I type instructions
                        //  Basic Arithmetic
                            (OPCODE_ADDIU) : begin
                                register[rt] <= (rt != 0) ? ($unsigned(register[rs]) + $unsigned(address_immediate)) : (0);
                            end

                        //  Bitwise operations
                            (OPCODE_ANDI) : begin
                                register[rd] <= (rt != 0) ? ($unsigned(register[rs]) & $unsigned(address_immediate)) : (0);
                            end

                            (OPCODE_ORI) : begin
                                register[rd] <= (rt != 0) ? ($unsigned(register[rs]) | $unsigned(address_immediate)) : (0);
                            end

                            (OPCODE_XORI) : begin
                                register[rd] <= (rt != 0) ? ($unsigned(register[rs]) ^ $unsigned(address_immediate)) : (0);
                            end

                        //  Load and sets
                            (OPCODE_LUI) : begin
                                register[rt] <= (rt != 0) ? (address_immediate << 16) : (0);
                            end

                            (OPCODE_SLTI) : begin
                                    register[rt] = (rt != 0) ? ((register[rs] < register[address_immediate]) ? (1) : (0)) : (0);
                            end

                            (OPCODE_SLTIU) : begin
                                    register[rt] = (rt != 0) ? (($unsigned(register[rs]) < $unsigned(register[address_immediate])) ? (1) : (0)) : (0);
                            end

                        //  Branch
                            //  Share opcode
                                (5'd1): begin   //  Is instruction BGEZ; BGEZAL; BLTZ; BLTZAL
                                    case (rt)
                                        (6'd1) : begin  //  BGTL
                                            // if (rs-rt) >= 0 then pc_next==immediate
                                            PC_next <= (register[rs] >= 0) ? (PC + (address_immediate << 2)) : (PC + 5'd4);
                                        end

                                        (6'd17) : begin //  BGTLAL
                                            PC_next <= (register[rs] >= 0) ? (PC + (address_immediate << 2)) : (PC + 5'd4);
                                            register[31] = PC;
                                        end

                                        (6'd0) : begin  //  BLTZ
                                            PC_next <= (register[rs] < 0) ? (PC + (address_immediate << 2)) : (PC + 5'd4);
                                        end

                                        (6'd16) : begin //  BLTZAL
                                            PC_next <= (register[rs] < 0) ? (PC + (address_immediate << 2)) : (PC + 5'd4);
                                            register[31] <= PC;
                                        end
                                    endcase
                                end

                            //  Rest
                                (OPCODE_BEQ) : begin
                                    PC_next <= (register[rs] == register[rt]) ? (PC + (address_immediate << 2)) : (PC + 5'd4);
                                end

                                (OPCODE_BGTZ) : begin
                                    PC_next <= (register[rs] > 0) ? (PC + (address_immediate << 2)) : (PC + 5'd4);
                                end

                                (OPCODE_BNE) : begin
                                    PC <= (register[rs] != register[rt]) ? (PC + (address_immediate << 2)) : (PC + 5'd4);
                                end

                                (OPCODE_BLEZ) : begin
                                    PC <= (register[rs] <= 0) ? (PC + (address_immediate << 2)) : (PC + 5'd4);
                                    //if (rs-rt)==0 or MSB(rs-rt)==1 then pc==immediate
                                end


                        //  Store   FIXME:  Not operational.
                                (OPCODE_SB) : begin
                                    /*  Write must be high
                                        setting values ton writedata
                                        byte enable will be us choosing byte at address
                                        Address is determined @ exec1
                                    */
                                    write = 1;  //  Enable write so that memory can be written upon
                                    address = (register[rs] + address_immediate);
                                    tempStoreReg = register[rt];
                                    case(address % 4)
                                        (0) : begin
                                            byteenable = (4'd1);    //  Byte enable the first byte
                                        end
                                        (1) : begin
                                            byteenable = (4'd2);    //  Byte enable the second byte
                                        end
                                        (2) : begin
                                            byteenable = (4'd4);    //  Byte enable the third byte
                                        end
                                        (3) : begin
                                            byteenable = (4'd8);    //  Byte enable the fourth byte
                                        end
                                    endcase
                                    writedata <= {24'd0, tempStoreReg[7:0]};   //  FIXME:   Error
                                end

                                (OPCODE_SH) : begin
                                    write = 1;  //  Enable write so that memory can be written upon
                                    address = (register[rs] + address_immediate);
                                    case(address % 2)
                                        (0) : begin
                                            byteenable = (4'd3);    //  Byte enable the first two bytes
                                        end
                                        (1) : begin
                                            byteenable = (4'd12);   //  Byte anable the latter two bytes
                                        end
                                    endcase
                                    writedata = {16'd0, tempStoreReg[15:0]};   //  FIXME:   Error
                                end

                                (OPCODE_SW) : begin
                                    write = 1;                  //  Enable write so that memory can be written upon
                                    address = (register[rs] + address_immediate);
                                    byteenable = 4'd15;           //  Byte enable all bytes
                                    writedata = register[rt];   //  Write
                                end

                endcase
                //  Load
                    if(lOp) begin
                        read = 1;
                        address = (register[rs] + address_immediate);
                    end
                //  Setting up for next state/stalls
                    state <= (!lOp) ? (FETCH) : (EXEC2);        //  Is it not a store operation?
                    //state <= (!multing) ? (EXEC1) : (state);    //  Has multiplication finished?  FIXME:  Problematic
                    PC <= (!lOp) ? (PC_next) : (PC);
            end
            (EXEC2) : begin
                //  Resetting read
                    read = 0;
                //  Load https://inst.eecs.berkeley.edu/~cs61c/resources/MIPS_help.html
                    case(opcode)
                            (OPCODE_LB) : begin
                                //  Load in the nth byte from the RAMs input to the CPU
                                //  Determine if latter 24 bits are 0 or 1
                                case(address % 4)
                                    (0): begin
                                        register[rt] = {((readdata[7]) ? (24'hFFF): (24'h0)), readdata[7:0]};
                                    end
                                    (1): begin
                                        register[rt] = {((readdata[15]) ? (24'hFFF): (24'h0)), readdata[15:8]};
                                    end
                                    (2): begin
                                        register[rt] = {((readdata[23]) ? (24'hFFF): (24'h0)), readdata[23:16]};
                                    end
                                    (3): begin
                                        register[rt] = {((readdata[31]) ? (24'hFFF): (24'h0)), readdata[31:24]};
                                    end
                                endcase
                            end

                            (OPCODE_LBU) : begin
                                //  Load in the nth byte from the RAMs input to the CPU (unsigned)
                                case(address % 4)
                                    (0):
                                        register[rt] = {24'b0, readdata[7:0]};
                                    (1):
                                        register[rt] = {24'b0, readdata[15:8]};
                                    (2):
                                        register[rt] = {24'b0, readdata[23:16]};
                                    (3):
                                        register[rt] = {24'b0, readdata[31:24]};
                                endcase
                            end

                            (OPCODE_LH) : begin
                                case(address % 2)
                                    (0):
                                        register[rt] = {((readdata[15]) ? (16'hFFF): (216'h0)), readdata[15:0]};
                                    (1):
                                        register[rt] = {((readdata[31]) ? (16'hFFF): (16'h0)), readdata[31:16]};
                                endcase
                            end

                            (OPCODE_LHU) : begin
                                case(address % 4)
                                    (0):
                                        register[rt] = {16'b0, readdata[15:0]};
                                    (1):
                                        register[rt] = {16'b0, readdata[31:16]};
                                endcase
                            end

                            (OPCODE_LW) : begin
                                    register[rt] = readdata;
                            end
                    endcase
                //  Next state
                    PC <= PC_next;
                    state <= (FETCH);
            end
            (HALT) : begin
                active <= 0;
                if (!waitrequest) begin
                    state <= FETCH; //  Might accidentally execute something if EXEC2 so set to FETCH?
                end
            end
        endcase
    end
endmodule