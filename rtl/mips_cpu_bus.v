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
*/
typedef enum logics[5:0]
{
    //OPCODE_ADDIU = 6'd,
    OPCODE_ADDU = 6'd33,
    OPCODE_AND = 6'd36,
    //OPCODE_ANDI = 6'd,
    //OPCODE_BGEZ = 6'd,
    OPCODE_BGEZAL = 6'd,
    OPCODE_BGTZ = 6'd,
    OPCODE_BLEZ = 6'd,
    OPCODE_BLTZ = 6'd,
    OPCODE_BLTZAL = 6'd,
    OPCODE_BNE = 6'd,
    OPCODE_DIV = 6'd,
    OPCODE_DIVU = 6'd,
    OPCOCE_J = 6'd
} opcode_t;

always_ff(posedge clk) begin
{
    $display("Suck your mum"); //I see
    // HELLO ADDING COMMENT HERE.
}
end 

end module