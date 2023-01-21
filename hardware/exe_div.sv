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
    // DIV -> IX
    output logic        div_ix_done,
    // DIV -> WB
    output logic        div_valid,
    output div_wb_inf_t div_wb_inf
);
    // Serial division FSM
    typedef enum {
        IDLE,
        BUSY,
        OUTPUT
    } state_t;

    state_t         state_reg, state_nxt;
    logic[5:0]      ctr_reg, ctr_nxt;

    logic           flip_quot_sign_reg, flip_quot_sign_nxt;
    logic           flip_rem_sign_reg, flip_rem_sign_nxt;
    logic           div_op_reg, div_op_nxt;
    logic[4:0]      rd_reg, rd_nxt;

    logic[31:0]     divisor_reg, divisor_nxt;
    logic[64:0]     rq_reg, rq_nxt;

    logic[32:0]     sub_result;

    logic           div_output_ready;
    logic           div_done_reg, div_done_nxt;

    always_ff @(posedge clk) begin
        if (rst) begin // Abort operation
            state_reg <= IDLE;
            ctr_reg <= 6'h0;
            div_done_reg <= 1'b0;
        end else begin
            state_reg <= state_nxt;
            ctr_reg <= ctr_nxt;
            div_done_reg <= div_done_nxt;
        end
    end

    always_ff @(posedge clk) begin
        flip_quot_sign_reg <= flip_quot_sign_nxt;
        flip_rem_sign_reg <= flip_rem_sign_nxt;

        div_op_reg <= div_op_nxt;

        divisor_reg <= divisor_nxt;
        rq_reg <= rq_nxt;

        rd_reg <= rd_nxt;
    end

    assign sub_result = rq_reg[63:32] - divisor_reg;

    // Next-state logic
    always_comb begin
        state_nxt = state_reg;
        ctr_nxt = ctr_reg;

        flip_quot_sign_nxt = flip_quot_sign_reg;
        flip_rem_sign_nxt = flip_rem_sign_reg;

        div_op_nxt = div_op_reg;

        divisor_nxt = divisor_reg;
        rq_nxt = rq_reg;

        rd_nxt = rd_reg;

        div_output_ready = 1'b0;
        div_done_nxt = 1'b0;

        case (state_reg)
            IDLE: begin
                ctr_nxt = 6'h20; // Serial division of N-bit word takes N+1 iterations

                flip_quot_sign_nxt = (ix_div_inf.rs1[31] ^ ix_div_inf.rs2[31]) &
                                     (~ix_div_inf.div_control[0]) & // DIV_OP_DIV or DIV_OP_REM
                                     (|ix_div_inf.rs2); // Don't negate if division-by-zero

                flip_rem_sign_nxt = ix_div_inf.rs1[31] &
                                    (~ix_div_inf.div_control[0]); // DIV_OP_DIV or DIV_OP_REM

                div_op_nxt = ~ix_div_inf.div_control[1]; // DIV_OP_DIV or DIV_OP_DIVU

                divisor_nxt = {((~ix_div_inf.div_control[0]) & ix_div_inf.rs2[31]) ? -$signed(ix_div_inf.rs2) :
                              ix_div_inf.rs2};

                rq_nxt = {32'h0, ((~ix_div_inf.div_control[0]) & ix_div_inf.rs1[31]) ? -$signed(ix_div_inf.rs1) :
                         ix_div_inf.rs1, 1'b0};

                rd_nxt = ix_div_inf.rd;

                if (ix_div_valid && !wb_do_branch)
                    state_nxt = BUSY; // Initiate division
            end

            BUSY: begin
                rq_nxt = {sub_result[32] ? rq_reg[63:32] : sub_result[31:0], rq_reg[31:0], ~sub_result[32]};
                ctr_nxt = ctr_reg - 6'b1;

                if (~(|ctr_nxt)) begin
                    state_nxt = OUTPUT; // End of serial division
                    div_done_nxt = 1'b1; // Signal the end of out-of-pipe division operation
                end
            end

            OUTPUT: begin
                div_output_ready = 1'b1;
                div_done_nxt = 1'b0;
                state_nxt = IDLE; // Result is ready and can be flushed
            end

            default: ;
        endcase
    end

    // Notify IX not to stall any longer
    assign div_ix_done = div_done_reg;

    always_ff @(posedge clk) div_valid <= div_output_ready;

    // Outputs to WB
    always_ff @(posedge clk) begin
        div_wb_inf.rd <= rd_reg;
        div_wb_inf.result <= div_op_reg ? (flip_quot_sign_reg ? -$signed(rq_reg[31:0]) : rq_reg[31:0]) :
                             (flip_rem_sign_reg ? -$signed(rq_reg[64:33]) : rq_reg[64:33]);
    end
endmodule