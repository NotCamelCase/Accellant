`include "defines.svh"

import defines::*;

module exe_mul
(
    input logic         clk, rst,
    // WB -> ALU
    input logic         wb_do_branch,
    // IX -> MUL
    input logic         ix_mul_valid,
    input ix_mul_inf_t  ix_mul_inf,
    // MUL -> WB
    output logic        mul_valid,
    output mul_wb_inf_t mul_wb_inf
);
    logic       s1_valid_reg;
    logic       s1_output_lower_reg;
    logic[4:0]  s1_rd_reg;
    logic[32:0] s1_a_reg, s1_b_reg;

    logic       s2_valid_reg;
    logic       s2_output_lower_reg;
    logic[4:0]  s2_rd_reg;
    logic[65:0] s2_result_reg;

    // Stage 1: Gather inputs to MUL op aligned to 33x33 bit signed/unsigned multiplication
    always_ff @(posedge clk) begin
        if (rst || wb_do_branch)
            s1_valid_reg <= 1'b0;
        else
            s1_valid_reg <= ix_mul_valid;
    end

    always_ff @(posedge clk) begin
        s1_output_lower_reg <= ix_mul_inf.mul_control == MUL_OP_MUL;
        s1_a_reg <= {((ix_mul_inf.mul_control == MUL_OP_MUL) || (ix_mul_inf.mul_control == MUL_OP_MULHU)) ? 1'b0 : ix_mul_inf.rs1[31], ix_mul_inf.rs1};;
        s1_b_reg <= {(ix_mul_inf.mul_control == MUL_OP_MULH) ? ix_mul_inf.rs2[31] : 1'b0, ix_mul_inf.rs2};
        s1_rd_reg <= ix_mul_inf.rd[4:0]; // x0-x32
    end

    // Stage 2: Do the product
    always_ff @(posedge clk) begin
        s2_valid_reg <= s1_valid_reg;
        s2_output_lower_reg <= s1_output_lower_reg;
        s2_rd_reg <= s1_rd_reg;
        s2_result_reg <= s1_a_reg * s1_b_reg;
    end

    // Stage 3: Outputs to WB
    always_ff @(posedge clk) begin
        mul_valid <= s2_valid_reg;
        mul_wb_inf.rd <= s2_rd_reg;
        mul_wb_inf.result <= s2_output_lower_reg ? s2_result_reg[31:0] : s2_result_reg[63:32];
    end
endmodule