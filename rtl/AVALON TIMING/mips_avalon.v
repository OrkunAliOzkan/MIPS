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

        OPCODE_BEQ = 6'd4,
        OPCODE_BGEZ = 6'd50,  //FIXME:    Need to differentiate by RT; Changed from 6'd1
        OPCODE_BGEZAL = 6'd51,//FIXME:    Need to differentiate by RT; Changed from 6'd1
        OPCODE_BGTZ = 6'd7,
        OPCODE_BLEZ = 6'd6,
        OPCODE_BLTZ = 6'd52,  //FIXME:    Need to differentiate by RT; Changed from 6'd1
        OPCODE_BLTZAL = 6'd53,//FIXME:    Need to differentiate by RT; Changed from 6'd1
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
        FUNCTION_CODE_MTLO = 6'd18,
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
        logic[31:0] PC;
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
        //  Memory access
            logic memOp; //  Are we accessing memory? Useful to differentiate
        //  Interupts
            logic stall;        //  Are we going to stall? Useful to differentiate

//  Initialising CPU
    initial begin
        //  Initialise register
            integer i;
            for(i = 0; i < 32; i++) begin
                register[i] = 32'b0;
            end
        //  Initialise interupt handles
            stall = 0;
        //  initialise state
            state = HALT;
            reset = 0;
    end

//  Automatic wire assignment
    //  Instruction register
        assign InstructionReg = (state == FETCH) ? (readdata) : (instructionReg);   //  Utilise instructionReg to keep contents up to date
    //  ALU wires
        assign shmat = InstructionReg[10:6];
        assign rs = InstructionReg[20:16];
        assign rt = InstructionReg[15:11];
        assign rd = InstructionReg[25:21];
        assign targetAddress = InstructionReg[25:0];
        assign address_immediate = InstructionReg[15:0];
    //  Temporary wires
        //  Multiplication
            //  FIXME:  Could be optimised
            assign multWire 
                =   ((state == EXEC) && (opcode == OPCODE_R)) ?
                        ((funct == FUNCTION_CODE_MULT) ? 
                            (register[rs] * register[rt]) : (0)) :
                        ((funct == FUNCTION_CODE_MULTU) ? 
                            ($unsigned(register[rs]) * $unsigned(register[rt])) : (0));
        //  Memory access
            assign memOp 
                = (((opcode == OPCODE_LB)   ||
                    (opcode == OPCODE_LBU)  ||
                    (opcode == OPCODE_LH)   ||
                    (opcode == OPCODE_LHU)  ||
                    (opcode == OPCODE_LW)   ||
                    (opcode == OPCODE_SB)   ||
                    (opcode == OPCODE_SW)   ||
                    (opcode == OPCODE_SH)));

//  Combinatorial block
    always_comb begin
        case (state) : begin
            (FETCH) : begin
                /*
                    Address is set to program counter, which requires read to be set to 1
                */
                read = 1;
                address = PC;
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
            state <= HALT;
            
        end

        case (state) : begin

            (FETCH) : begin
                if (address == 32'd0) begin

                end
                else begin

                end
            end

            (EXEC1) : begin
            end
            (EXEC2) : begin
            end
            (HALT) : begin
            end
    end