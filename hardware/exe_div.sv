`include "defines.svh"

module exe_div
(
    input logic                 clk, rst,
    // From Core
    input logic                 stall,
    input logic                 flush,
    // To DISPATCHER
    output logic                div_done,
    // From DISPATCHER
    input dispatcher_div_inf_t  dispatcher_div_inf,
    // To WB
    output exe_wb_inf_t         div_wb_inf
);
    // Serial division FSM
    typedef enum {
        IDLE,
        BUSY
    } state_t;

    state_t     state_reg, state_nxt;
    logic       div_done_reg, div_done_nxt;
    logic[5:0]  ctr_reg, ctr_nxt;

    logic       flip_quot_sign_reg, flip_quot_sign_nxt;
    logic       flip_rem_sign_reg, flip_rem_sign_nxt;
    logic       div_op_reg, div_op_nxt;
    logic[4:0]  rd_reg, rd_nxt;

    logic[31:0] divisor_reg, divisor_nxt;
    logic[64:0] rq_reg, rq_nxt;

    logic[32:0] sub_result;

    always_ff @(posedge clk) begin
        if (flush) // Abort operation
            state_reg <= IDLE;
        else if (!stall)
            state_reg <= state_nxt;
    end

    always_ff @(posedge clk) begin
        if (rst)
            div_done_reg <= `FALSE;
        else if (!stall)
            div_done_reg <= div_done_nxt;

        ctr_reg <= ctr_nxt;
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
        div_done_nxt = div_done_reg;
        ctr_nxt = ctr_reg;

        flip_quot_sign_nxt = flip_quot_sign_reg;
        flip_rem_sign_nxt = flip_rem_sign_reg;

        div_op_nxt = div_op_reg;

        divisor_nxt = divisor_reg;
        rq_nxt = rq_reg;

        rd_nxt = rd_reg;

        case (state_reg)
            IDLE: begin
                div_done_nxt = `FALSE;
                ctr_nxt = '0;

                flip_quot_sign_nxt = (dispatcher_div_inf.rs1[31] ^ dispatcher_div_inf.rs2[31]) &
                                     (~dispatcher_div_inf.ctrl.div_control[0]) & // DIV_OP_DIV or DIV_OP_REM
                                     (|dispatcher_div_inf.rs2); // Don't negate if division-by-zero

                flip_rem_sign_nxt = dispatcher_div_inf.rs1[31] &
                                    (~dispatcher_div_inf.ctrl.div_control[0]); // DIV_OP_DIV or DIV_OP_REM

                div_op_nxt = ~dispatcher_div_inf.ctrl.div_control[1]; // DIV_OP_DIV or DIV_OP_DIVU

                divisor_nxt = {((~dispatcher_div_inf.ctrl.div_control[0]) & dispatcher_div_inf.rs2[31]) ? -$signed(dispatcher_div_inf.rs2) :
                              dispatcher_div_inf.rs2};

                rq_nxt = {32'h0, ((~dispatcher_div_inf.ctrl.div_control[0]) & dispatcher_div_inf.rs1[31]) ? -$signed(dispatcher_div_inf.rs1) :
                         dispatcher_div_inf.rs1, 1'b0};

                rd_nxt = dispatcher_div_inf.rd;

                if (dispatcher_div_inf.ctrl.instruction_valid)
                    state_nxt = BUSY; // Initiate division
            end

            BUSY: begin
                if (ctr_reg != 6'h20) begin
                    rq_nxt = {sub_result[32] ? rq_reg[63:32] : sub_result[31:0], rq_reg[31:0], ~sub_result[32]};
                    ctr_nxt = ctr_reg + 1;
                end else begin
                    state_nxt = IDLE;
                    div_done_nxt = `TRUE;
                end
            end

            default: ;
        endcase
    end

    always_ff @(posedge clk) begin
        // No latching required due to out-of-pipeline execution
        div_wb_inf.instruction_valid <= div_done_reg;
        div_wb_inf.register_write <= `TRUE;
        div_wb_inf.rd <= REG_WIDTH'(rd_reg);
        div_wb_inf.exe_result <= div_op_reg ? (flip_quot_sign_reg ? -$signed(rq_reg[31:0]) : rq_reg[31:0]) :
                                 (flip_rem_sign_reg ? -$signed(rq_reg[64:33]) : rq_reg[64:33]);
    end

    // Notify Dispatcher that Divider is done, so it can continue issuing instructions
    assign div_done = div_done_reg;
endmodule