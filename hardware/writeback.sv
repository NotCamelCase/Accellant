`include "defines.svh"

module writeback
(
    input logic                 clk, rst,
    // From ALU
    input exe_wb_inf_t          alu_wb_inf,
    // From LSU
    input exe_wb_inf_t          mem_wb_inf,
    // To DISPATCHER
    output wb_dispatcher_inf_t  wb_dispatcher_inf
);
    logic                   wr_en;
    logic[REG_WIDTH-1:0]    rd;
    logic[31:0]             wr_data;

    always_ff @(posedge clk) begin
        if (rst) begin
            wb_dispatcher_inf.wr_en <= `FALSE;
        end else begin
            wb_dispatcher_inf.wr_en <= wr_en;
            wb_dispatcher_inf.rd <= rd;
            wb_dispatcher_inf.wr_data <= wr_data;
        end
    end

    // MUX EXE payloads to write-back to register file
    always_comb begin
        wr_en = alu_wb_inf.instruction_valid ? alu_wb_inf.register_write :
                (mem_wb_inf.instruction_valid ? mem_wb_inf.register_write : `FALSE);

        rd = alu_wb_inf.instruction_valid ? alu_wb_inf.rd :
             (mem_wb_inf.instruction_valid ? mem_wb_inf.rd : '0);

        wr_data = alu_wb_inf.instruction_valid ? alu_wb_inf.exe_result :
                  (mem_wb_inf.instruction_valid ? mem_wb_inf.exe_result : 32'h0);
    end
endmodule