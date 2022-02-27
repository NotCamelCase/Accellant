`include "defines.svh"

module mem_lsu
(
    input logic                 clk, rst,
    // From DISPATCHER
    input dispatcher_lsu_inf_t  dispatcher_lsu_inf,
    // To WB
    output exe_wb_inf_t         mem_wb_inf
);
    localparam  MEM_SIZE    =   4096; // 16 KB Data Memory

    logic[2:0]  lsu_control_reg;
    logic[1:0]  load_selector_reg;

    logic       mem_store, mem_load;
    logic[3:0]  byte_en;
    logic[31:0] mem_addr;
    logic[31:0] wr_data;
    logic[31:0] rd_data;

    logic[3:0]  sb_wr_en, sh_wr_en, sw_wr_en;
    logic[7:0]  lb_rd_data;
    logic[15:0] lh_rd_data;
    logic[31:0] lw_rd_data;
    logic[31:0] sb_wr_data, sh_wr_data, sw_wr_data;

    logic[31:0] lb_sext;
    logic[31:0] lbu_zext;
    logic[31:0] lw;
    logic[31:0] lh_sext;
    logic[31:0] lhu_zext;

    //TODO: Handle misaligned memory accesses?

    // Instantiate a byte-addreseable BRAM
    bram_1r1w #(.ADDR_WIDTH($clog2(MEM_SIZE)), .DATA_WIDTH(32), .NUM_COL(4)) memory(
        .clk(clk),
        .wr_en(byte_en),
        .rd_addr({mem_addr[11:2], 2'b0}),
        .wr_addr({mem_addr[11:2], 2'b0}),
        .wr_data(wr_data),
        .rd_data(rd_data));

    // Register LSU op and LSB bits to adjust load result correctly
    always_ff @(posedge clk) lsu_control_reg <= dispatcher_lsu_inf.ctrl.lsu_control;
    always_ff @(posedge clk) load_selector_reg <= mem_addr[1:0];

    // LSU payload
    always_ff @(posedge clk) begin
        mem_wb_inf.instruction_valid <= dispatcher_lsu_inf.ctrl.instruction_valid;
        mem_wb_inf.register_write <= dispatcher_lsu_inf.ctrl.register_write;
        mem_wb_inf.rd <= dispatcher_lsu_inf.rd;
    end

    // Memory location to access -> rs1 + immediate
    assign mem_addr = dispatcher_lsu_inf.rs1 + dispatcher_lsu_inf.imm_ext;

    //TODO: Take all necessary stall/flush and control signals into account!
    assign mem_store = dispatcher_lsu_inf.ctrl.mem_store & dispatcher_lsu_inf.ctrl.instruction_valid;
    assign mem_load = dispatcher_lsu_inf.ctrl.mem_load & dispatcher_lsu_inf.ctrl.instruction_valid;

    // Adjust byte-enable for SB/SH/SW
    assign sb_wr_en = 4'b0001 << mem_addr[1:0];
    assign sh_wr_en = mem_addr[0] ? 4'b1100 : 4'b0011;
    assign sw_wr_en = 4'b1111;

    assign byte_en = {4{mem_store}} &
                     ((dispatcher_lsu_inf.ctrl.lsu_control[1:0] == STORE_OP_SB) ? sb_wr_en :
                     ((dispatcher_lsu_inf.ctrl.lsu_control[1:0] == STORE_OP_SH) ? sh_wr_en :
                     sw_wr_en));

    // Align write data for SB/SH/SW
    always_comb begin
        unique case (mem_addr[1:0])
            2'b11: sb_wr_data = {dispatcher_lsu_inf.write_data[7:0], 24'b0};
            2'b10: sb_wr_data = {8'b0, dispatcher_lsu_inf.write_data[7:0], 16'b0};
            2'b01: sb_wr_data = {16'b0, dispatcher_lsu_inf.write_data[7:0], 8'b0};
            default: sb_wr_data = {24'b0, dispatcher_lsu_inf.write_data[7:0]};
        endcase
    end

    assign sh_wr_data = mem_addr[0] ? {dispatcher_lsu_inf.write_data[15:0], 16'b0} : {16'b0, dispatcher_lsu_inf.write_data[15:0]};
    assign sw_wr_data = dispatcher_lsu_inf.write_data;

    // Select byte, half-word or word to write to memory
    assign wr_data = ((dispatcher_lsu_inf.ctrl.lsu_control[1:0] == STORE_OP_SB) ? sb_wr_data : 32'h0) ^
                     ((dispatcher_lsu_inf.ctrl.lsu_control[1:0] == STORE_OP_SH) ? sh_wr_data : 32'h0) ^
                     ((dispatcher_lsu_inf.ctrl.lsu_control[1:0] == STORE_OP_SW) ? sw_wr_data : 32'h0);

    // Byte/half-word/word selection
    always_comb begin
        unique case (load_selector_reg)
            2'b11: lb_rd_data = rd_data[31:24];
            2'b10: lb_rd_data = rd_data[23:16];
            2'b01: lb_rd_data = rd_data[15:8];
            default: lb_rd_data = rd_data[7:0];
        endcase
    end

    assign lh_rd_data = load_selector_reg[0] ? rd_data[31:16] : rd_data[15:0];
    assign lw_rd_data = rd_data;

    assign lb_sext = (lsu_control_reg == LOAD_OP_LB) ? {{24{lb_rd_data[7]}}, lb_rd_data} : 32'h0;
    assign lbu_zext = (lsu_control_reg == LOAD_OP_LBU) ? {24'b0, lb_rd_data} : 32'h0;
    assign lh_sext = (lsu_control_reg == LOAD_OP_LH) ? {{16{lh_rd_data[15]}}, lh_rd_data} : 32'h0;
    assign lhu_zext = (lsu_control_reg == LOAD_OP_LHU) ? {16'b0, lh_rd_data} : 32'h0;
    assign lw = (lsu_control_reg == LOAD_OP_LW) ? lw_rd_data : 32'h0;

    // Outputs
    assign mem_wb_inf.exe_result = lb_sext ^ lbu_zext ^ lh_sext ^ lhu_zext ^ lw;
endmodule
