/**
 * @MIPS CPU
 * @brief:  Design a MIPS I CPU with Vonn Neuman architecture
 * @version 0.1
 * @date 2021-11-22
 *
 * @copyright Copyright (c) 2021
 *
 */

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
    R types have an opcode of 0d0, therefore are differentiated through their function codes
    J types have an opcode of 0d2 and 0d3, therefore don't need to have their opcode specified
    I type uniques opcodes
    
    I type formatting:  For Transfer, branch and immedaiate instructions
*/
typedef enum logics[5:0]
{
    ITYPE_ADDIU = 6'd9,
    ITYPE_ANDI = 6'd12,
    ITYPE_BEQ = 6'd4,
    ITYPE_BGEZ = 6'd1,  //FIXME:    Need to differentiate by RT
    ITYPE_BGEZAL = 6'd1,//FIXME:    Need to differentiate by RT
    ITYPE_BGTZ = 6'd7,
    ITYPE_BLEZ = 6'd6,
    ITYPE_BLTZ = 6'd1,  //FIXME:    Need to differentiate by RT
    ITYPE_BLTZAL = 6'd1,//FIXME:    Need to differentiate by RT
    ITYPE_BNE = 6'd5,
    ITYPE_LUI = 6'd15,
    ITYPE_ORI = 6'd13,
    ITYPE_SLTI = 6'd10,
    ITYPE_SLTIU = 6'd11,
    ITYPE_XORI = 6'd14
    ITYPE_LB = 6'd32,
    ITYPE_LBU = 6'd36,
    ITYPE_LH = 6'd33,
    ITYPE_LHU = 6'd37,
    ITYPE_LW = 6'd35,
    ITYPE_SB = 6'd40,
    ITYPE_SH = 6'd41,
    ITYPE_SW = 6'd43,
} i_type_opcode;


/*
    R types are differentiated through their function code
*/
typedef enum logics[5:0]
{
    //  TODO:   Are move functions R type?
    FUNCTION_CODE_ADDU = 6'd33,
    FUNCTION_CODE_AND = 6'd36,
    FUNCTION_CODE_OR = 6'd37,
    FUNCTION_CODE_SLT = 6'd42,
    FUNCTION_CODE_SLTU = 6'd43,
    FUNCTION_CODE_SUBU = 6'd35,
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
    FUNCTION_CODE_LWR = 6'd,    //FIXME:Hmmm
    FUNCTION_CODE_LWL = 6'd,    //FIXME:Hmmm
} fcode_t;

typedef enum logics[1:0]
{
    FETCH = 2'd0,
    EXEC1 = 2'd1,
    EXEC2 = 2'd2,
    HALTED = 2'd3
} state_t;

    logic[31:0] PC, PC_next, PC_jump;
    logic[1:0] state;
    //EDIT

    /*
    Not sure where to put, but opcode stuff

    logic[31:0] instr;
    assign logic[31:0] opcode = instr[31:26];

    if (!opcode) begin
        // R-TYPE
        // SOURCE 1 = instr[25:21];
        // SOURCE 2 = instr[20:16];
        // DEST = instr[15:11];
        // SHIFT = instr[10:6];
        // Function code = instr[5:0];
    end
    else if (opcode[1] == 1) begin
        // J-TYPE
        // ADDR = instr[25:0];
    end
    else begin
        // I-TYPE
        // SOURCE 1 = instr[25:21];
        // SOURCE 2/DEST = instr[20:16];
        // ADDR/DATA = instr[15:0];
    end

    */

    always_ff(posedge clk) begin
    {

        if (state == state_t.FETCH) begin //FETCH
            PC_next <= PC + 4;
        end
        else if (state == state_t.EXEC1) begin //EXEC1
            
        end
        else if (state == state_t.EXEC2) begin //EXEC2
            
        end

    }
    end



endmodule
