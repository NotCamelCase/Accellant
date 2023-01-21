`include "defines.svh"

import defines::*;

module riscv_core
(
    input logic         clk, rst,
    // I/O Bus
    output logic        io_bus_rd_en,
    output logic        io_bus_wr_en,
    output logic[31:0]  io_bus_address,
    output logic[31:0]  io_bus_wr_data,
    input logic[31:0]   io_bus_rd_data,
    // AXI Instruction Bus
    output logic[31:0]  axi_ibus_awaddr,
    output logic[1:0]   axi_ibus_awburst,
    output logic[7:0]   axi_ibus_awlen,
    output logic[2:0]   axi_ibus_awsize,
    output logic        axi_ibus_awvalid,
    input logic         axi_ibus_awready,
    output logic[31:0]  axi_ibus_wdata,
    output logic[3:0]   axi_ibus_wstrb,
    output logic        axi_ibus_wlast,
    output logic        axi_ibus_wvalid,
    input logic         axi_ibus_wready,
    input logic[1:0]    axi_ibus_bresp,
    input logic         axi_ibus_bvalid,
    output logic        axi_ibus_bready,
    output logic[31:0]  axi_ibus_araddr,
    output logic[7:0]   axi_ibus_arlen,
    output logic[2:0]   axi_ibus_arsize,
    output logic[1:0]   axi_ibus_arburst,
    output logic        axi_ibus_arvalid,
    input logic         axi_ibus_arready,
    input logic[31:0]   axi_ibus_rdata,
    input logic[1:0]    axi_ibus_rresp,
    input logic         axi_ibus_rvalid,
    input logic         axi_ibus_rlast,
    output logic        axi_ibus_rready,
    // AXI Data Bus
    output logic[31:0]  axi_dbus_awaddr,
    output logic[1:0]   axi_dbus_awburst,
    output logic[7:0]   axi_dbus_awlen,
    output logic[2:0]   axi_dbus_awsize,
    output logic        axi_dbus_awvalid,
    input logic         axi_dbus_awready,
    output logic[31:0]  axi_dbus_wdata,
    output logic[3:0]   axi_dbus_wstrb,
    output logic        axi_dbus_wlast,
    output logic        axi_dbus_wvalid,
    input logic         axi_dbus_wready,
    input logic[1:0]    axi_dbus_bresp,
    input logic         axi_dbus_bvalid,
    output logic        axi_dbus_bready,
    output logic[31:0]  axi_dbus_araddr,
    output logic[7:0]   axi_dbus_arlen,
    output logic[2:0]   axi_dbus_arsize,
    output logic[1:0]   axi_dbus_arburst,
    output logic        axi_dbus_arvalid,
    input logic         axi_dbus_arready,
    input logic[31:0]   axi_dbus_rdata,
    input logic[1:0]    axi_dbus_rresp,
    input logic         axi_dbus_rvalid,
    input logic         axi_dbus_rlast,
    output logic        axi_dbus_rready
);
    logic                               ift_valid;
    ift_ifd_inf_t                       ift_ifd_inf;
    ifd_ift_inf_t                       ifd_ift_inf;
    logic                               ifd_valid;
    ifd_id_inf_t                        ifd_id_inf;
    logic                               id_valid;
    id_ix_inf_t                         id_ix_inf;

    logic                               ix_stall_if;

    logic                               ix_alu_valid;
    ix_alu_inf_t                        ix_alu_inf;

    logic                               ix_lst_valid;
    ix_lst_inf_t                        ix_lst_inf;

    logic                               ix_mul_valid;
    ix_mul_inf_t                        ix_mul_inf;

    logic                               ix_div_valid;
    ix_div_inf_t                        ix_div_inf;
    logic                               div_ix_done;

    logic                               alu_valid;
    alu_wb_inf_t                        alu_wb_inf;

    logic                               lst_valid;
    lst_lsd_inf_t                       lst_lsd_inf;
    dcache_tag_t[DCACHE_NUM_WAYS-1:0]   lst_writeback_tags;

    lsd_lst_inf_t                       lsd_lst_inf;
    logic                               lsd_dcache_flush_done;

    logic                               lsd_valid;
    lsd_wb_inf_t                        lsd_wb_inf;
    logic                               mul_valid;
    mul_wb_inf_t                        mul_wb_inf;

    logic                               div_valid;
    div_wb_inf_t                        div_wb_inf;

    wb_ix_inf_t                         wb_ix_inf;

    logic                               wb_do_branch, wb_icache_invalidate;
    logic[31:0]                         wb_branch_target;

    instruction_fetch_tag ift(.*);
    instruction_fetch_data ifd(.*);
    instruction_decode id(.*);
    instruction_issue ix(.*);
    exe_alu alu(.*);
    load_store_tag lst(.*);
    load_store_data lsd(.*);
    exe_mul mul(.*);
    exe_div div(.*);
    writeback wb(.*);
endmodule