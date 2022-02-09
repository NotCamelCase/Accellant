`include "defines.svh"

module writeback
(
    input logic                 clk, rst,
    // From ALU
    input exe_wb_inf_t          alu_wb_inf,
    // From LSU
    input exe_wb_inf_t          mem_wb_inf,
    // From MUL
    input exe_wb_inf_t          mul_wb_inf,
    // From DIV
    input exe_wb_inf_t          div_wb_inf,
    // To DISPATCHER
    output wb_dispatcher_inf_t  wb_dispatcher_inf
);
    // Collect and MUX EXE payloads to be written back to register file
    always_ff @(posedge clk) begin
        if (rst) begin
            wb_dispatcher_inf.wr_en <= `FALSE;
        end else begin
            wb_dispatcher_inf.wr_en <=
                (alu_wb_inf.instruction_valid & alu_wb_inf.register_write) |
                (mem_wb_inf.instruction_valid & mem_wb_inf.register_write) |
                (mul_wb_inf.instruction_valid & mul_wb_inf.register_write) |
                (div_wb_inf.instruction_valid & div_wb_inf.register_write);

            wb_dispatcher_inf.rd <= 
                ({REG_WIDTH{alu_wb_inf.instruction_valid}} & alu_wb_inf.rd) |
                ({REG_WIDTH{mem_wb_inf.instruction_valid}} & mem_wb_inf.rd) |
                ({REG_WIDTH{mul_wb_inf.instruction_valid}} & mul_wb_inf.rd) |
                ({REG_WIDTH{div_wb_inf.instruction_valid}} & div_wb_inf.rd);

            wb_dispatcher_inf.wr_data <=
                ({32{alu_wb_inf.instruction_valid}} & alu_wb_inf.exe_result) |
                ({32{mem_wb_inf.instruction_valid}} & mem_wb_inf.exe_result) |
                ({32{mul_wb_inf.instruction_valid}} & mul_wb_inf.exe_result) |
                ({32{div_wb_inf.instruction_valid}} & div_wb_inf.exe_result);
        end
    end
endmodule