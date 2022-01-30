`include "defines.svh"

module instruction_fetch
#
(
    parameter TEST_PROG = "test.mem",
    parameter READ_HEX  = "YES"
)
(
    input logic         clk, rst,
    // From Core
    input logic         pc_src,
    input logic[31:0]   branch_target,
    input logic         stall,
    input logic         flush,
    // To ID
    output if_id_inf_t  if_id_inf
);
    // Max number of instructions
    localparam  MAX_PROG_SIZE   = 1024; // 4KB Instruction ROM

    // Start instructions from this address upon reset
    localparam  RESET_PC        = 32'h0;

    // PC
    logic[31:0] pc_reg;
    
    logic[31:0] pc_inc;

    // Fetched instruction
    logic[31:0] instruction;

    // PC registers
    always_ff @(posedge clk) begin
        if (rst)
            pc_reg <= RESET_PC;
        else if (!stall)
            pc_reg <= pc_src ? {branch_target[31:1], 1'b0} : pc_inc;
    end

    assign pc_inc = pc_reg + 32'h4;

    // Instruction memory (true ROM)
    true_rom #(
        .ROM_FILE(TEST_PROG),
        .READ_HEX(READ_HEX),
        .ADDR_WIDTH($clog2(MAX_PROG_SIZE)),
        .DATA_WIDTH(32)) instruction_rom(
            .addr(pc_reg[11:2]),
            .data(instruction));

    always_ff @(posedge clk) begin
        if (flush) begin
            if_id_inf.instr <= 32'h0;
        end else if (!stall) begin
            if_id_inf.pc <= pc_reg;
            if_id_inf.pc_inc <= pc_inc;
            if_id_inf.instr <= instruction;
        end
    end
endmodule