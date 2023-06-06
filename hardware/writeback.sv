`include "defines.svh"

import defines::*;

module writeback
#(OPT_REG_OUTPUTS = 1'b1)
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
    output logic[31:0]      wb_branch_target,
    output logic[31:0]      wb_control_flow_pc
);
    // LSU load op delivery
    logic[7:0]                  lb_rd_data;
    logic[15:0]                 lh_rd_data;
    logic[31:0]                 lsu_result;

    // Outputs
    logic                       wr_en;
    logic[REG_WIDTH-1:0]        rd;
    logic[31:0]                 wr_data;

    logic[NUM_EXE_PIPES-1:0]    mux_sel;

    assign mux_sel = { div_valid, mul_valid, lsd_valid, alu_valid };

    // Handle branch requests from ALU or LSU
    assign wb_do_branch = alu_wb_inf.do_branch || lsd_wb_inf.do_branch;
    assign wb_icache_invalidate = alu_wb_inf.icache_invalidate;
    assign wb_branch_target = {alu_wb_inf.do_branch ? alu_wb_inf.branch_target[31:2] : lsd_wb_inf.branch_target[31:2], 2'b0};
    assign wb_control_flow_pc = alu_wb_inf.do_branch ? alu_wb_inf.control_flow_pc : lsd_wb_inf.control_flow_pc;

    // Byte/half-word/word selection
    always_comb begin
        unique case (lsd_wb_inf.load_selector)
            2'b11: lb_rd_data = lsd_wb_inf.load_result[31:24];
            2'b10: lb_rd_data = lsd_wb_inf.load_result[23:16];
            2'b01: lb_rd_data = lsd_wb_inf.load_result[15:8];
            default: lb_rd_data = lsd_wb_inf.load_result[7:0];
        endcase
    end

    always_comb begin
        unique case (lsd_wb_inf.load_selector)
            2'b10: lh_rd_data = lsd_wb_inf.load_result[31:16];
            default: lh_rd_data = lsd_wb_inf.load_result[15:0];
        endcase
    end

    always_comb begin
        unique case (lsd_wb_inf.load_control)
            LOAD_OP_LB: lsu_result = {{24{lb_rd_data[7]}}, lb_rd_data};  // LB
            LOAD_OP_LBU: lsu_result = {24'b0, lb_rd_data};               // LBU
            LOAD_OP_LH: lsu_result = {{16{lh_rd_data[15]}}, lh_rd_data}; // LH
            LOAD_OP_LHU: lsu_result = {16'b0, lh_rd_data};               // LHU
            default: lsu_result = lsd_wb_inf.load_result;                // LW
        endcase
    end

    // Collect EXE payloads
    always_comb begin
        casez (mux_sel)
            4'b???1: wr_en = alu_wb_inf.register_write; // ALU
            4'b??10: wr_en = lsd_wb_inf.register_write; // LSU
            // MUL/DIV always have results written back.
            4'b?100: wr_en = 1'b1;                      // MUL
            4'b1000: wr_en = 1'b1;                      // DIV
            default: wr_en = 1'b0;
        endcase
    end

    always_comb begin
        casez (mux_sel)
            4'b???1: rd = alu_wb_inf.rd; // ALU
            4'b??10: rd = lsd_wb_inf.rd; // LSU
            4'b?100: rd = mul_wb_inf.rd; // MUL
            4'b1000: rd = div_wb_inf.rd; // DIV
            default: rd = '0;
        endcase
    end

    always_comb begin
        casez (mux_sel)
            4'b???1: wr_data = alu_wb_inf.exe_result; // ALU
            4'b??10: wr_data = lsu_result;            // LSU
            4'b?100: wr_data = mul_wb_inf.result;     // MUL
            4'b1000: wr_data = div_wb_inf.result;     // DIV
            default: wr_data = {32{1'bx}};
        endcase
    end

    // Outputs
    generate
        if (OPT_REG_OUTPUTS == 1'b1) begin
            always_ff @(posedge clk) begin
                wb_ix_inf.wr_en <= wr_en;
                wb_ix_inf.rd <= rd;
                wb_ix_inf.wr_data <= wr_data;
            end
        end else begin
            always_comb begin
                wb_ix_inf.wr_en = wr_en;
                wb_ix_inf.rd = rd;
                wb_ix_inf.wr_data = wr_data;
            end
        end
    endgenerate
endmodule