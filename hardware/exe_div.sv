`include "defines.svh"

import defines::*;

module exe_div
(
    input logic         clk, rst,
    // WB -> DIV
    input logic         wb_do_branch,
    // IX -> DIV
    input logic         ix_div_valid,
    input ix_div_inf_t  ix_div_inf,
    // DIV -> WB
    output logic        div_valid,
    output div_wb_inf_t div_wb_inf
);
    localparam  PIPE_DIV_LATENCY = 16;

    logic           flip_sign_rem, flip_sign_qout;
    logic           div_valid_tmp;
    logic[4:0]      rd_dly;
    logic[63:0]     div_result_tmp;

    logic           flip_quot_sign_dly, flip_rem_sign_dly, div_op_dly;
    logic           div_input_valid_reg, div_valid_reg;
    logic[4:0]      rd_reg;
    logic[31:0]     divisor_reg, dividend_reg, div_output_reg;

    // DIV input stage
    always_ff @(posedge clk) begin
        div_input_valid_reg <= ix_div_valid && !wb_do_branch;

        divisor_reg <= {((~ix_div_inf.div_control[0]) & ix_div_inf.rs2[31]) ? -$signed(ix_div_inf.rs2) : ix_div_inf.rs2};
        dividend_reg <= {((~ix_div_inf.div_control[0]) & ix_div_inf.rs1[31]) ? -$signed(ix_div_inf.rs1) : ix_div_inf.rs1};
    end

    pipelined_divider divider(
        .aclk(clk),
        .s_axis_divisor_tvalid(div_input_valid_reg),
        .s_axis_divisor_tdata(divisor_reg),
        .s_axis_dividend_tvalid(div_input_valid_reg),
        .s_axis_dividend_tdata(dividend_reg),
        .m_axis_dout_tvalid(div_valid_tmp),
        .m_axis_dout_tdata(div_result_tmp));

    // DIV output stage
    always_ff @(posedge clk) begin
        rd_reg <= rd_dly;
        div_valid_reg <= div_valid_tmp;
        div_output_reg <= div_op_dly ? (flip_quot_sign_dly ? -$signed(div_result_tmp[63:32]) : div_result_tmp[63:32]) :
                          (flip_rem_sign_dly ? -$signed(div_result_tmp[31:0]) : div_result_tmp[31:0]);
    end

    shift_register #(.WIDTH(5), .DELAY_COUNT(PIPE_DIV_LATENCY+1)) dly_rd(
    	.clk(clk),
        .d(ix_div_inf.rd),
        .q(rd_dly));

    shift_register #(.WIDTH(1), .DELAY_COUNT(PIPE_DIV_LATENCY+1)) dly_flip_sign_rem(
        .clk(clk),
        .d(flip_sign_rem),
        .q(flip_rem_sign_dly));

    shift_register #(.WIDTH(1), .DELAY_COUNT(PIPE_DIV_LATENCY+1)) dly_flip_sign_qout(
        .clk(clk),
        .d(flip_sign_qout),
        .q(flip_quot_sign_dly));

    shift_register #(.WIDTH(1), .DELAY_COUNT(PIPE_DIV_LATENCY+1)) dly_div_op(
        .clk(clk),
        .d(~ix_div_inf.div_control[1]), // DIV_OP_DIV or DIV_OP_DIVU),
        .q(div_op_dly));

    assign flip_sign_rem = (ix_div_inf.rs1[31] ^ ix_div_inf.rs2[31]) &
                           (~ix_div_inf.div_control[0]) & // DIV_OP_DIV or DIV_OP_REM
                           (|ix_div_inf.rs2); // Don't negate if division-by-zero

    assign flip_sign_qout = ix_div_inf.rs1[31] &
                            (~ix_div_inf.div_control[0]); // DIV_OP_DIV or DIV_OP_REM

    // Outputs to WB
    assign div_valid = div_valid_reg;
    assign div_wb_inf.rd = rd_reg;
    assign div_wb_inf.result = div_output_reg;
endmodule