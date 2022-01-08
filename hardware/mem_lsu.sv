`include "defines.svh"

module mem_lsu
(
    input logic         clk, rst,
    // From EXE
    input exe_mem_inf_t exe_mem_inf,
    // To WB
    output mem_wb_inf_t mem_wb_inf
);
    localparam  MEM_SIZE    =   4096; // 16 KB Data Memory

    bram_1r1w #(.ADDR_WIDTH($clog2(MEM_SIZE)), .DATA_WIDTH(32)) memory(
        .clk(clk),
        //TODO: Byte-addressabiltiy?!
        .rd_addr(exe_mem_inf.alu_result[11:0]),
        .wr_addr(exe_mem_inf.alu_result[11:0]),
        .wr_en(exe_mem_inf.ctrl.mem_store),
        .wr_data(exe_mem_inf.write_data),
        .rd_data(mem_wb_inf.read_data));

    // Propagate control signals to WB
    always_ff @(posedge clk) begin
        if (rst) begin
            mem_wb_inf.ctrl.mem_load <= 1'b0;
            mem_wb_inf.ctrl.register_write <= 1'b0;
            mem_wb_inf.ctrl.result_src <= 2'b0;
        end else begin
            mem_wb_inf.ctrl.mem_load <= exe_mem_inf.ctrl.mem_load;
            mem_wb_inf.ctrl.register_write <= exe_mem_inf.ctrl.register_write;
            mem_wb_inf.ctrl.result_src <= exe_mem_inf.ctrl.result_src;
        end
    end

    always_ff @(posedge clk) begin
        mem_wb_inf.rd <= exe_mem_inf.rd;
        mem_wb_inf.alu_result <= exe_mem_inf.alu_result;
        mem_wb_inf.pc_inc <= exe_mem_inf.pc_inc;
    end
endmodule