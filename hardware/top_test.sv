module top_test
(
    input logic         clk100,
    input logic         arstn,
    output logic[3:0]   led,
    output logic        uart_rx,
    input logic         uart_tx,
    output logic[3:0]   r, g, b,
    output logic        hsync, vsync,
    // DDR3 inf
    output logic        ddr3_reset_n,
    output logic        ddr3_cke,
    output logic        ddr3_ck_p,
    output logic        ddr3_ck_n,
    output logic        ddr3_cs_n,
    output logic        ddr3_ras_n,
    output logic        ddr3_cas_n,
    output logic        ddr3_we_n,
    output logic[2:0]   ddr3_ba,
    output logic[13:0]  ddr3_addr,
    output logic[0:0]   ddr3_odt,
    output logic[1:0]   ddr3_dm,
    inout logic[1:0]    ddr3_dqs_p,
    inout logic[1:0]    ddr3_dqs_n,
    inout logic[15:0]   ddr3_dq
);
    localparam  LED_COUNT   = 4;

    // DDR3
    logic       ddr3_init_calib_complete;
    logic       ddr3_app_sr_active;
    logic       ddr3_app_ref_ack;
    logic       ddr3_app_zq_ack;
    logic       ddr3_ui_clk;
    logic       ddr3_ui_clk_sync_rst;
    logic       ddr3_clk_ref_i;

    // AXI dbus slave
    logic[31:0] axi_dbus_awaddr;
    logic[1:0]  axi_dbus_awburst;
    logic[7:0]  axi_dbus_awlen;
    logic[2:0]  axi_dbus_awsize;
    logic       axi_dbus_awvalid;
    logic       axi_dbus_awready;
    logic[31:0] axi_dbus_wdata;
    logic[3:0]  axi_dbus_wstrb;
    logic       axi_dbus_wlast;
    logic       axi_dbus_wvalid;
    logic       axi_dbus_wready;
    logic[1:0]  axi_dbus_bresp;
    logic       axi_dbus_bvalid;
    logic       axi_dbus_bready;
    logic[31:0] axi_dbus_araddr;
    logic[7:0]  axi_dbus_arlen;
    logic[2:0]  axi_dbus_arsize;
    logic[1:0]  axi_dbus_arburst;
    logic       axi_dbus_arvalid;
    logic       axi_dbus_arready;
    logic[31:0] axi_dbus_rdata;
    logic[1:0]  axi_dbus_rresp;
    logic       axi_dbus_rvalid;
    logic       axi_dbus_rlast;
    logic       axi_dbus_rready;

    logic[31:0] axi_sdram_awaddr;
    logic[1:0]  axi_sdram_awburst;
    logic[7:0]  axi_sdram_awlen;
    logic[2:0]  axi_sdram_awsize;
    logic       axi_sdram_awvalid;
    logic       axi_sdram_awready;
    logic[31:0] axi_sdram_wdata;
    logic[3:0]  axi_sdram_wstrb;
    logic       axi_sdram_wlast;
    logic       axi_sdram_wvalid;
    logic       axi_sdram_wready;
    logic[1:0]  axi_sdram_bresp;
    logic       axi_sdram_bvalid;
    logic       axi_sdram_bready;
    logic[31:0] axi_sdram_araddr;
    logic[7:0]  axi_sdram_arlen;
    logic[2:0]  axi_sdram_arsize;
    logic[1:0]  axi_sdram_arburst;
    logic       axi_sdram_arvalid;
    logic       axi_sdram_arready;
    logic[31:0] axi_sdram_rdata;
    logic[1:0]  axi_sdram_rresp;
    logic       axi_sdram_rvalid;
    logic       axi_sdram_rlast;
    logic       axi_sdram_rready;

    logic       clk, clk_sys;
    logic       mmcm_locked;
    logic       rst, rstn_mig_axi;

    sync_reset reset(
    	.clk(clk),
        .arstn(arstn),
        .rst(rst));

    clk_gen mmcm(
        .clk_in(clk100),
        .clk_sys(clk_sys),
        .clk100(clk),
        .clk200(ddr3_clk_ref_i));

    // Keep SDRAM AXI inf in reset until device bring-up
    always_ff @(posedge ddr3_ui_clk) rstn_mig_axi <= ~ddr3_ui_clk_sync_rst & ddr3_init_calib_complete & mmcm_locked;

    accellant_soc_sdram #(.LED_COUNT(LED_COUNT)) soc(.*);

    // CDC for handling SoC <-> SDRAM AXI traffic
    axi_cdc core_sdram_cdc(
        .s_axi_aclk(clk),
        .s_axi_aresetn(~rst),
        .s_axi_awaddr(axi_dbus_awaddr),
        .s_axi_awlen(axi_dbus_awlen),
        .s_axi_awsize(axi_dbus_awsize),
        .s_axi_awburst(axi_dbus_awburst),
        .s_axi_awlock(1'b0),
        .s_axi_awcache('0),
        .s_axi_awprot('0),
        .s_axi_awqos('0),
        .s_axi_awregion('0),
        .s_axi_awvalid(axi_dbus_awvalid),
        .s_axi_awready(axi_dbus_awready),
        .s_axi_wdata(axi_dbus_wdata),
        .s_axi_wstrb(axi_dbus_wstrb),
        .s_axi_wlast(axi_dbus_wlast),
        .s_axi_wvalid(axi_dbus_wvalid),
        .s_axi_wready(axi_dbus_wready),
        .s_axi_bresp(axi_dbus_bresp),
        .s_axi_bvalid(axi_dbus_bvalid),
        .s_axi_bready(axi_dbus_bready),
        .s_axi_araddr(axi_dbus_araddr),
        .s_axi_arlen(axi_dbus_arlen),
        .s_axi_arsize(axi_dbus_arsize),
        .s_axi_arburst(axi_dbus_arburst),
        .s_axi_arvalid(axi_dbus_arvalid),
        .s_axi_arready(axi_dbus_arready),
        .s_axi_arlock(1'b0),
        .s_axi_arcache('0),
        .s_axi_arprot('0),
        .s_axi_arqos('0),
        .s_axi_arregion('0),
        .s_axi_rdata(axi_dbus_rdata),
        .s_axi_rresp(axi_dbus_rresp),
        .s_axi_rlast(axi_dbus_rlast),
        .s_axi_rvalid(axi_dbus_rvalid),
        .s_axi_rready(axi_dbus_rready),
        .m_axi_aclk(ddr3_ui_clk),
        .m_axi_aresetn(rstn_mig_axi),
        .m_axi_awaddr(axi_sdram_awaddr),
        .m_axi_awlen(axi_sdram_awlen),
        .m_axi_awsize(axi_sdram_awsize),
        .m_axi_awburst(axi_sdram_awburst),
        .m_axi_awlock(),
        .m_axi_awcache(),
        .m_axi_awprot(),
        .m_axi_awregion(),
        .m_axi_awqos(),
        .m_axi_awvalid(axi_sdram_awvalid),
        .m_axi_awready(axi_sdram_awready),
        .m_axi_wdata(axi_sdram_wdata),
        .m_axi_wstrb(axi_sdram_wstrb),
        .m_axi_wlast(axi_sdram_wlast),
        .m_axi_wvalid(axi_sdram_wvalid),
        .m_axi_wready(axi_sdram_wready),
        .m_axi_bresp(axi_sdram_bresp),
        .m_axi_bvalid(axi_sdram_bvalid),
        .m_axi_bready(axi_sdram_bready),
        .m_axi_araddr(axi_sdram_araddr),
        .m_axi_arlen(axi_sdram_arlen),
        .m_axi_arsize(axi_sdram_arsize),
        .m_axi_arburst(axi_sdram_arburst),
        .m_axi_arlock(),
        .m_axi_arcache(),
        .m_axi_arprot(),
        .m_axi_arregion(),
        .m_axi_arqos(),
        .m_axi_arvalid(axi_sdram_arvalid),
        .m_axi_arready(axi_sdram_arready),
        .m_axi_rdata(axi_sdram_rdata),
        .m_axi_rresp(axi_sdram_rresp),
        .m_axi_rlast(axi_sdram_rlast),
        .m_axi_rvalid(axi_sdram_rvalid),
        .m_axi_rready(axi_sdram_rready));

    mig_sdram mig_sdram(
        .ddr3_addr(ddr3_addr),
        .ddr3_ba(ddr3_ba),
        .ddr3_cas_n(ddr3_cas_n),
        .ddr3_ck_n(ddr3_ck_n),
        .ddr3_ck_p(ddr3_ck_p),
        .ddr3_cke(ddr3_cke),
        .ddr3_ras_n(ddr3_ras_n),
        .ddr3_reset_n(ddr3_reset_n),
        .ddr3_we_n(ddr3_we_n),
        .ddr3_dq(ddr3_dq),
        .ddr3_dqs_n(ddr3_dqs_n),
        .ddr3_dqs_p(ddr3_dqs_p),
        .init_calib_complete(ddr3_init_calib_complete),
	    .ddr3_cs_n(ddr3_cs_n),
        .ddr3_dm(ddr3_dm),
        .ddr3_odt(ddr3_odt),
        // Application interface ports
        .ui_clk(ddr3_ui_clk),
        .ui_clk_sync_rst(ddr3_ui_clk_sync_rst),
        .mmcm_locked(mmcm_locked),
        .aresetn(1'b1),
        .app_sr_req(1'b0),
        .app_ref_req(1'b0),
        .app_zq_req(1'b0),
        .app_sr_active(ddr3_app_sr_active),
        .app_ref_ack(ddr3_app_ref_ack),
        .app_zq_ack(ddr3_app_zq_ack),
        .s_axi_awid('0),
        .s_axi_awaddr(axi_sdram_awaddr),
        .s_axi_awlen(axi_sdram_awlen),
        .s_axi_awsize(axi_sdram_awsize),
        .s_axi_awburst(axi_sdram_awburst),
        .s_axi_awlock(1'b0),
        .s_axi_awcache('0),
        .s_axi_awprot('0),
        .s_axi_awqos('0),
        .s_axi_awvalid(axi_sdram_awvalid),
        .s_axi_awready(axi_sdram_awready),
        .s_axi_wdata(axi_sdram_wdata),
        .s_axi_wstrb(axi_sdram_wstrb),
        .s_axi_wlast(axi_sdram_wlast),
        .s_axi_wvalid(axi_sdram_wvalid),
        .s_axi_wready(axi_sdram_wready),
        .s_axi_bid(),
        .s_axi_bresp(axi_sdram_bresp),
        .s_axi_bvalid(axi_sdram_bvalid),
        .s_axi_bready(axi_sdram_bready),
        .s_axi_arid('0),
        .s_axi_araddr(axi_sdram_araddr),
        .s_axi_arlen(axi_sdram_arlen),
        .s_axi_arsize(axi_sdram_arsize),
        .s_axi_arburst(axi_sdram_arburst),
        .s_axi_arvalid(axi_sdram_arvalid),
        .s_axi_arready(axi_sdram_arready),
        .s_axi_arlock(1'b0),
        .s_axi_arcache('0),
        .s_axi_arprot('0),
        .s_axi_arqos('0),
        .s_axi_rid(),
        .s_axi_rdata(axi_sdram_rdata),
        .s_axi_rresp(axi_sdram_rresp),
        .s_axi_rlast(axi_sdram_rlast),
        .s_axi_rvalid(axi_sdram_rvalid),
        .s_axi_rready(axi_sdram_rready),
        .sys_clk_i(clk_sys),
        .clk_ref_i(ddr3_clk_ref_i),
        .sys_rst(~arstn)); // Active-high reset
endmodule