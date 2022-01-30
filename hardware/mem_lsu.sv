`include "defines.svh"

module mem_lsu
(
    input logic                 clk, rst,
    // From Core
    input logic                 stall,
    input logic                 flush,
    // From DISPATCHER
    input dispatcher_lsu_inf_t  dispatcher_lsu_inf,
    // To WB
    output exe_wb_inf_t         mem_wb_inf
);
    localparam  MEM_SIZE    =   4096; // 16 KB Data Memory

    logic       mem_store, mem_load;
    logic[31:0] mem_addr;

    bram_1r1w #(.ADDR_WIDTH($clog2(MEM_SIZE)), .DATA_WIDTH(32)) memory(
        .clk(clk),
        //TODO: Byte-addressabiltiy?!
        .rd_addr(mem_addr[11:0]),
        .wr_addr(mem_addr[11:0]),
        .wr_en(mem_store),
        .wr_data(dispatcher_lsu_inf.write_data),
        .rd_data(mem_wb_inf.exe_result));

    // Propagate signals to WB
    always_ff @(posedge clk) begin
        if (flush) begin
            mem_wb_inf.instruction_valid <= `FALSE;
            mem_wb_inf.register_write <= `FALSE;
        end else if (!stall) begin
            mem_wb_inf.instruction_valid <= dispatcher_lsu_inf.ctrl.instruction_valid;
            mem_wb_inf.register_write <= dispatcher_lsu_inf.ctrl.register_write;
            mem_wb_inf.rd <= dispatcher_lsu_inf.rd;
        end
    end

    // Memory location to access <= rs1 + immediate
    assign mem_addr = dispatcher_lsu_inf.rs1 + dispatcher_lsu_inf.imm_ext;

    //TODO: Take all necessary stall/flush and control signals into account!
    assign mem_store = dispatcher_lsu_inf.ctrl.mem_store & dispatcher_lsu_inf.ctrl.instruction_valid;
    assign mem_load = dispatcher_lsu_inf.ctrl.mem_load & dispatcher_lsu_inf.ctrl.instruction_valid;
endmodule