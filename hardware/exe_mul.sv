`include "defines.svh"

module exe_mul
(
    input logic                 clk, rst,
    // From DISPATCHER
    input dispatcher_mul_inf_t  dispatcher_mul_inf,
    // To WB
    output exe_wb_inf_t         mul_wb_inf
);
    typedef struct packed {
        logic       valid;        // Also register_write, which is on for all MUL ops
        logic       output_lower; // Select upper or lower word as output
        logic[4:0]  rd;           // Only scalar registers, hence range [4:0]
    } mul_input_t;

    logic[32:0] mul_src_a, mul_src_b;
    logic[65:0] mul_result;

    mul_input_t mul_input, mul_input_dly;

    assign mul_src_a = ((dispatcher_mul_inf.ctrl.mul_control == MUL_OP_MUL) ||
                       (dispatcher_mul_inf.ctrl.mul_control == MUL_OP_MULHU)) ? {1'b0, dispatcher_mul_inf.rs1} :
                       {dispatcher_mul_inf.rs1[31], dispatcher_mul_inf.rs1};

    assign mul_src_b = (dispatcher_mul_inf.ctrl.mul_control == MUL_OP_MULH) ? {dispatcher_mul_inf.rs2[31], dispatcher_mul_inf.rs2} :
                       {1'b0, dispatcher_mul_inf.rs2};

    // Gather inputs to MUL op
    assign mul_input.valid = dispatcher_mul_inf.ctrl.instruction_valid;
    assign mul_input.output_lower = dispatcher_mul_inf.ctrl.mul_control == MUL_OP_MUL;
    assign mul_input.rd = dispatcher_mul_inf.rd[4:0]; // x0-x32

    // Delay MUL inputs toward valid output
    shift_register #(.WIDTH($bits(mul_input_t)), .DELAY_COUNT(LATENCY_MUL_OP)) dly_mul_input(
        .clk(clk),
        .d(mul_input),
        .q(mul_input_dly));

    // Signed integer multiplier
    core_int32_mul_dsp multiplier(
        .CLK(clk),
        .A(mul_src_a),
        .B(mul_src_b),
        .P(mul_result));

    // MUL payload
    always_ff @(posedge clk) begin
        mul_wb_inf.instruction_valid <= mul_input_dly.valid;
        mul_wb_inf.register_write <= `TRUE;
        mul_wb_inf.rd <= REG_WIDTH'(mul_input_dly.rd);
        mul_wb_inf.exe_result <= mul_input_dly.output_lower ? mul_result[31:0] : mul_result[63:32];
    end
endmodule
