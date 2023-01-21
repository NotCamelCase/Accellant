`include "defines.svh"

import defines::*;

module writeback
(
    input logic             clk, rst,
    // ALU -> WB
    input logic             alu_valid,
    input alu_wb_inf_t      alu_wb_inf,
    // LSD -> WB
    input logic             lsd_valid,
    input lsd_wb_inf_t      lsd_wb_inf,
    // MUL -> WB
    input logic             mul_valid,
    input mul_wb_inf_t      mul_wb_inf,
    // DIV -> WB
    input logic             div_valid,
    input div_wb_inf_t      div_wb_inf,
    // WB -> IX
    output wb_ix_inf_t      wb_ix_inf,
    // WB -> IFT/IFD/ID/IX/EXE
    output logic            wb_do_branch,
    output logic            wb_icache_invalidate,
    output logic[31:0]      wb_branch_target
);
    // LSU load op delivery
    logic[7:0]                  lb_rd_data;
    logic[15:0]                 lh_rd_data;
    logic[31:0]                 lw_rd_data;
    logic[31:0]                 lb_sext;
    logic[31:0]                 lbu_zext;
    logic[31:0]                 lw;
    logic[31:0]                 lh_sext;
    logic[31:0]                 lhu_zext;

    // Handle branch requests from ALU or LSU
    assign wb_do_branch = alu_wb_inf.do_branch || lsd_wb_inf.do_branch;
    assign wb_icache_invalidate = alu_wb_inf.icache_invalidate;
    assign wb_branch_target = {alu_wb_inf.do_branch ? alu_wb_inf.branch_target[31:2] : lsd_wb_inf.branch_target[31:2], 2'b0};

    // Byte/half-word/word selection
    always_comb begin
        unique case (lsd_wb_inf.load_selector)
            2'b11: lb_rd_data = lsd_wb_inf.load_result[31:24];
            2'b10: lb_rd_data = lsd_wb_inf.load_result[23:16];
            2'b01: lb_rd_data = lsd_wb_inf.load_result[15:8];
            default: lb_rd_data = lsd_wb_inf.load_result[7:0];
        endcase
    end

    assign lh_rd_data = lsd_wb_inf.load_selector[0] ? lsd_wb_inf.load_result[31:16] : lsd_wb_inf.load_result[15:0];
    assign lw_rd_data = lsd_wb_inf.load_result;

    assign lb_sext = (lsd_wb_inf.load_control == LOAD_OP_LB) ? {{24{lb_rd_data[7]}}, lb_rd_data} : 32'h0;
    assign lbu_zext = (lsd_wb_inf.load_control == LOAD_OP_LBU) ? {24'b0, lb_rd_data} : 32'h0;
    assign lh_sext = (lsd_wb_inf.load_control == LOAD_OP_LH) ? {{16{lh_rd_data[15]}}, lh_rd_data} : 32'h0;
    assign lhu_zext = (lsd_wb_inf.load_control == LOAD_OP_LHU) ? {16'b0, lh_rd_data} : 32'h0;
    assign lw = (lsd_wb_inf.load_control == LOAD_OP_LW) ? lw_rd_data : 32'h0;

    // Collect EXE payloads
    always_ff @(posedge clk) begin
        wb_ix_inf.wr_en <=
            (alu_valid & alu_wb_inf.register_write) |
            (lsd_valid & lsd_wb_inf.register_write) |
            // MUL/DIV always have results written back.
            mul_valid |
            div_valid;

        wb_ix_inf.rd <=
            ({REG_WIDTH{alu_valid}} & alu_wb_inf.rd) |
            ({REG_WIDTH{lsd_valid}} & lsd_wb_inf.rd) |
            ({REG_WIDTH{mul_valid}} & mul_wb_inf.rd) |
            ({REG_WIDTH{div_valid}} & div_wb_inf.rd);

        wb_ix_inf.wr_data <=
            ({32{alu_valid}} & alu_wb_inf.exe_result) |
            ({32{lsd_valid}} & (lb_sext ^ lbu_zext ^ lh_sext ^ lhu_zext ^ lw)) |
            ({32{mul_valid}} & mul_wb_inf.result) |
            ({32{div_valid}} & div_wb_inf.result);
    end
endmodule