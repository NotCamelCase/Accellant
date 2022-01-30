`include "defines.svh"

module riscv_core
#
(
    parameter   TEST_PROG   = "test.mem",
    parameter   READ_HEX    = "YES"
)
(
    input logic         clk, rst,
    output logic[3:0]   led
);
    logic[3:0]  led_reg;

    always_ff @(posedge clk) led_reg <= {4{if_id_inf.pc == 32'h20}};

    assign led = led_reg;

    if_id_inf_t             if_id_inf;
    id_dispatcher_inf_t     id_dispatcher_inf;
    dispatcher_alu_inf_t    dispatcher_alu_inf;
    dispatcher_lsu_inf_t    dispatcher_lsu_inf;
    exe_wb_inf_t            alu_wb_inf;
    exe_wb_inf_t            mem_wb_inf;
    wb_dispatcher_inf_t     wb_dispatcher_inf;

    logic                   branch_taken;
    logic[31:0]             branch_target;

    logic                   stall_fetch, stall_decode, stall_dispatcher, stall_alu, stall_mem;
    logic                   flush_decode, flush_dispatcher, flush_exe, flush_writeback;
    logic                   dispatcher_conflict;

    // Pipeline stall & flush logic
    always_comb begin
        stall_fetch = dispatcher_conflict && ~(branch_taken);
        stall_decode = dispatcher_conflict && ~(branch_taken);
        stall_dispatcher = `FALSE;
        stall_alu = `FALSE;
        stall_mem = `FALSE;

        flush_decode = rst || branch_taken;
        flush_dispatcher = rst || branch_taken;
        flush_exe = rst || dispatcher_conflict || branch_taken;
        flush_writeback = rst;
    end

    instruction_fetch #(.TEST_PROG(TEST_PROG), .READ_HEX(READ_HEX)) ifetch(
        .clk(clk),
        .rst(rst),
        .pc_src(branch_taken),
        .branch_target(branch_target),
        .stall(stall_fetch),
        .flush(flush_decode),
        .if_id_inf(if_id_inf));

    instruction_decode idecode(
        .clk(clk),
        .rst(rst),
        .stall(stall_decode),
        .flush(flush_dispatcher),
        .if_id_inf(if_id_inf),
        .id_dispatcher_inf(id_dispatcher_inf));

    dispatcher dispatch_unit(
        .clk(clk),
        .rst(rst),
        .stall(stall_dispatcher),
        .flush(flush_exe),
        .dispatcher_conflict(dispatcher_conflict),
        .id_dispatcher_inf(id_dispatcher_inf),
        .wb_dispatcher_inf(wb_dispatcher_inf),
        .dispatcher_alu_inf(dispatcher_alu_inf),
        .dispatcher_lsu_inf(dispatcher_lsu_inf));

    exe_alu alu(
        .clk(clk),
        .rst(rst),
        .stall(stall_alu),
        .flush(flush_writeback),
        .dispatcher_alu_inf(dispatcher_alu_inf),
        .branch_taken(branch_taken),
        .branch_target(branch_target),
        .alu_wb_inf(alu_wb_inf));

    mem_lsu lsu(
        .clk(clk),
        .rst(rst),
        .stall(stall_mem),
        .flush(flush_writeback),
        .dispatcher_lsu_inf(dispatcher_lsu_inf),
        .mem_wb_inf(mem_wb_inf));

    writeback writeback_unit(
        .clk(clk),
        .rst(rst),
        .alu_wb_inf(alu_wb_inf),
        .mem_wb_inf(mem_wb_inf),
        .wb_dispatcher_inf(wb_dispatcher_inf));
endmodule