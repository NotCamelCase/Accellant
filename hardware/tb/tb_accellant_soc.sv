`timescale 1ns/1ps

module tb_accellant_soc;
    localparam  COL_WIDTH              = 10; // # of memory Column Address bits.
    localparam  CS_WIDTH               = 1; // # of unique CS outputs to memory.
    localparam  DM_WIDTH               = 2; // # of DM (data mask)
    localparam  DQ_WIDTH               = 16; // # of DQ (data)
    localparam  DQS_WIDTH              = 2;
    localparam  DQS_CNT_WIDTH          = 1; // = ceil(log2(DQS_WIDTH))
    localparam  DRAM_WIDTH             = 8; // # of DQ per DQS
    localparam  RANKS                  = 1; // # of Ranks.
    localparam  ODT_WIDTH              = 1; // # of ODT outputs to memory.
    localparam  ROW_WIDTH              = 14; // # of memory Row Address bits.
    localparam  ADDR_WIDTH             = 28;
    localparam  CA_MIRROR              = "OFF"; // C/A mirror opt for DDR3 dual rank

    localparam real TPROP_DQS          = 0.00; // Delay for DQS signal during Write Operation
    localparam real TPROP_DQS_RD       = 0.00; // Delay for DQS signal during Read Operation
    localparam real TPROP_PCB_CTRL     = 0.00; // Delay for Address and Ctrl signals
    localparam real TPROP_PCB_DATA     = 0.00; // Delay for data signal during Write operation
    localparam real TPROP_PCB_DATA_RD  = 0.00; // Delay for data signal during Read operation

    localparam MEMORY_WIDTH            = 16;
    localparam NUM_COMP                = DQ_WIDTH/MEMORY_WIDTH;

    // Clock period
    localparam  T = 10;

    localparam  LED_COUNT   = 4;

    // Inputs
    logic                   clk100; // 10 ns
    logic                   arstn; // Async active-low
    logic                   uart_tx;
    // Outputs
    logic[LED_COUNT-1:0]    led;
    logic                   uart_rx;

    // DDR3
    wire                    ddr3_reset_n;
    wire[DQ_WIDTH-1:0]      ddr3_dq_fpga;
    wire[DQS_WIDTH-1:0]     ddr3_dqs_p_fpga;
    wire[DQS_WIDTH-1:0]     ddr3_dqs_n_fpga;
    wire[ROW_WIDTH-1:0]     ddr3_addr_fpga;
    wire[2:0]               ddr3_ba_fpga;
    wire                    ddr3_ras_n_fpga;
    wire                    ddr3_cas_n_fpga;
    wire                    ddr3_we_n_fpga;
    wire                    ddr3_cke_fpga;
    wire                    ddr3_ck_p_fpga;
    wire                    ddr3_ck_n_fpga;

    wire[(CS_WIDTH*1)-1:0]  ddr3_cs_n_fpga;
    wire[DM_WIDTH-1:0]      ddr3_dm_fpga;
    wire[ODT_WIDTH-1:0]     ddr3_odt_fpga;

    reg[(CS_WIDTH*1)-1:0]   ddr3_cs_n_sdram_tmp;
    reg[DM_WIDTH-1:0]       ddr3_dm_sdram_tmp;
    reg[ODT_WIDTH-1:0]      ddr3_odt_sdram_tmp;
    wire [DQ_WIDTH-1:0]     ddr3_dq_sdram;
    reg[ROW_WIDTH-1:0]      ddr3_addr_sdram [0:1];
    reg[2:0]                ddr3_ba_sdram [0:1];
    reg                     ddr3_ras_n_sdram;
    reg                     ddr3_cas_n_sdram;
    reg                     ddr3_we_n_sdram;
    wire[(CS_WIDTH*1)-1:0]  ddr3_cs_n_sdram;
    wire[ODT_WIDTH-1:0]     ddr3_odt_sdram;
    reg                     ddr3_cke_sdram;
    wire [DM_WIDTH-1:0]     ddr3_dm_sdram;
    wire [DQS_WIDTH-1:0]    ddr3_dqs_p_sdram;
    wire [DQS_WIDTH-1:0]    ddr3_dqs_n_sdram;
    reg                     ddr3_ck_p_sdram;
    reg                     ddr3_ck_n_sdram;

    logic                   ddr3_init_calib_complete;
    logic                   ddr3_app_sr_active;
    logic                   ddr3_app_ref_ack;
    logic                   ddr3_app_zq_ack;
    logic                   ddr3_ui_clk;
    logic                   ddr3_ui_clk_sync_rst;
    logic                   ddr3_clk_ref_i;

    // AXI dbus slave
    logic[31:0]             axi_dbus_awaddr;
    logic[1:0]              axi_dbus_awburst;
    logic[7:0]              axi_dbus_awlen;
    logic[2:0]              axi_dbus_awsize;
    logic                   axi_dbus_awvalid;
    logic                   axi_dbus_awready;
    logic[31:0]             axi_dbus_wdata;
    logic[3:0]              axi_dbus_wstrb;
    logic                   axi_dbus_wlast;
    logic                   axi_dbus_wvalid;
    logic                   axi_dbus_wready;
    logic[1:0]              axi_dbus_bresp;
    logic                   axi_dbus_bvalid;
    logic                   axi_dbus_bready;
    logic[31:0]             axi_dbus_araddr;
    logic[7:0]              axi_dbus_arlen;
    logic[2:0]              axi_dbus_arsize;
    logic[1:0]              axi_dbus_arburst;
    logic                   axi_dbus_arvalid;
    logic                   axi_dbus_arready;
    logic[31:0]             axi_dbus_rdata;
    logic[1:0]              axi_dbus_rresp;
    logic                   axi_dbus_rvalid;
    logic                   axi_dbus_rlast;
    logic                   axi_dbus_rready;

    logic[31:0]             axi_sdram_awaddr;
    logic[1:0]              axi_sdram_awburst;
    logic[7:0]              axi_sdram_awlen;
    logic[2:0]              axi_sdram_awsize;
    logic                   axi_sdram_awvalid;
    logic                   axi_sdram_awready;
    logic[31:0]             axi_sdram_wdata;
    logic[3:0]              axi_sdram_wstrb;
    logic                   axi_sdram_wlast;
    logic                   axi_sdram_wvalid;
    logic                   axi_sdram_wready;
    logic[1:0]              axi_sdram_bresp;
    logic                   axi_sdram_bvalid;
    logic                   axi_sdram_bready;
    logic[31:0]             axi_sdram_araddr;
    logic[7:0]              axi_sdram_arlen;
    logic[2:0]              axi_sdram_arsize;
    logic[1:0]              axi_sdram_arburst;
    logic                   axi_sdram_arvalid;
    logic                   axi_sdram_arready;
    logic[31:0]             axi_sdram_rdata;
    logic[1:0]              axi_sdram_rresp;
    logic                   axi_sdram_rvalid;
    logic                   axi_sdram_rlast;
    logic                   axi_sdram_rready;

    logic                   clk, clk_sys;
    logic                   mmcm_locked;
    logic                   rst, rstn_mig_axi;

    // 100 Mhz input clock
    initial
        clk100 = 1'b0;
    always
        clk100 = #(T/2) ~clk100;

    // 100 Mhz DDR3 input clock
    initial
        clk_sys = 1'b0;
    always
        clk_sys = #(T/2) ~clk_sys;

    // 200 Mhz DDR3 ref clock input
    initial
        ddr3_clk_ref_i = 1'b0;
    always
        ddr3_clk_ref_i = #T ~ddr3_clk_ref_i;

    initial begin
        arstn = 1'b0;
        #(10*T);
        arstn = 1'b1;
    end

    // SoC clock
    assign clk = clk100;

    sync_reset reset(
    	.clk(clk),
        .arstn(arstn),
        .rst(rst));

    always_ff @(posedge ddr3_ui_clk) rstn_mig_axi <= ~ddr3_ui_clk_sync_rst & ddr3_init_calib_complete & mmcm_locked;

    accellant_soc_sdram #(.LED_COUNT(LED_COUNT)) soc(.*);

    // CDC for handling SoC <-> SDRAM traffic
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
        .m_axi_aresetn(~ddr3_ui_clk_sync_rst),
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
        .aresetn(rstn_mig_axi), // Active-low
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

    always @( * ) begin
        ddr3_ck_p_sdram      <=  #(TPROP_PCB_CTRL) ddr3_ck_p_fpga;
        ddr3_ck_n_sdram      <=  #(TPROP_PCB_CTRL) ddr3_ck_n_fpga;
        ddr3_addr_sdram[0]   <=  #(TPROP_PCB_CTRL) ddr3_addr_fpga;
        ddr3_addr_sdram[1]   <=  #(TPROP_PCB_CTRL) (CA_MIRROR == "ON") ?
                                                    {ddr3_addr_fpga[ROW_WIDTH-1:9],
                                                    ddr3_addr_fpga[7], ddr3_addr_fpga[8],
                                                    ddr3_addr_fpga[5], ddr3_addr_fpga[6],
                                                    ddr3_addr_fpga[3], ddr3_addr_fpga[4],
                                                    ddr3_addr_fpga[2:0]} :
                                                    ddr3_addr_fpga;
        ddr3_ba_sdram[0]     <=  #(TPROP_PCB_CTRL) ddr3_ba_fpga;
        ddr3_ba_sdram[1]     <=  #(TPROP_PCB_CTRL) (CA_MIRROR == "ON") ?
                                                    {ddr3_ba_fpga[3-1:2],
                                                    ddr3_ba_fpga[0],
                                                    ddr3_ba_fpga[1]} :
                                                    ddr3_ba_fpga;
        ddr3_ras_n_sdram     <=  #(TPROP_PCB_CTRL) ddr3_ras_n_fpga;
        ddr3_cas_n_sdram     <=  #(TPROP_PCB_CTRL) ddr3_cas_n_fpga;
        ddr3_we_n_sdram      <=  #(TPROP_PCB_CTRL) ddr3_we_n_fpga;
        ddr3_cke_sdram       <=  #(TPROP_PCB_CTRL) ddr3_cke_fpga;
    end

    always @( * ) ddr3_cs_n_sdram_tmp <=  #(TPROP_PCB_CTRL) ddr3_cs_n_fpga;
    always @( * ) ddr3_dm_sdram_tmp <= #(TPROP_PCB_DATA) ddr3_dm_fpga;//DM signal generation
    always @( * ) ddr3_odt_sdram_tmp <=  #(TPROP_PCB_CTRL) ddr3_odt_fpga;

    assign ddr3_cs_n_sdram =  ddr3_cs_n_sdram_tmp;
    assign ddr3_dm_sdram = ddr3_dm_sdram_tmp;
    assign ddr3_odt_sdram =  ddr3_odt_sdram_tmp;

    // Controlling the bi-directional BUS
    genvar dqwd;
    generate
    for (dqwd = 1;dqwd < DQ_WIDTH;dqwd = dqwd+1) begin : dq_delay
        WireDelay #
        (
        .Delay_g    (TPROP_PCB_DATA),
        .Delay_rd   (TPROP_PCB_DATA_RD),
        .ERR_INSERT ("OFF")
        )
        u_delay_dq
        (
        .A             (ddr3_dq_fpga[dqwd]),
        .B             (ddr3_dq_sdram[dqwd]),
        .reset         (arstn),
        .phy_init_done (ddr3_init_calib_complete)
        );
    end
            WireDelay #
        (
        .Delay_g    (TPROP_PCB_DATA),
        .Delay_rd   (TPROP_PCB_DATA_RD),
        .ERR_INSERT ("OFF")
        )
        u_delay_dq_0
        (
        .A             (ddr3_dq_fpga[0]),
        .B             (ddr3_dq_sdram[0]),
        .reset         (arstn),
        .phy_init_done (ddr3_init_calib_complete)
        );
    endgenerate

    genvar dqswd;
    generate
    for (dqswd = 0;dqswd < DQS_WIDTH;dqswd = dqswd+1) begin : dqs_delay
        WireDelay #
        (
        .Delay_g    (TPROP_DQS),
        .Delay_rd   (TPROP_DQS_RD),
        .ERR_INSERT ("OFF")
        )
        u_delay_dqs_p
        (
        .A             (ddr3_dqs_p_fpga[dqswd]),
        .B             (ddr3_dqs_p_sdram[dqswd]),
        .reset         (arstn),
        .phy_init_done (ddr3_init_calib_complete)
        );

        WireDelay #
        (
        .Delay_g    (TPROP_DQS),
        .Delay_rd   (TPROP_DQS_RD),
        .ERR_INSERT ("OFF")
        )
        u_delay_dqs_n
        (
        .A             (ddr3_dqs_n_fpga[dqswd]),
        .B             (ddr3_dqs_n_sdram[dqswd]),
        .reset         (arstn),
        .phy_init_done (ddr3_init_calib_complete)
        );
    end
    endgenerate

    //**************************************************************************//
    // Memory Models instantiations
    //**************************************************************************//
    genvar r,i;
    generate
    for (r = 0; r < CS_WIDTH; r = r + 1) begin: mem_rnk
        if(DQ_WIDTH/16) begin: mem
        for (i = 0; i < NUM_COMP; i = i + 1) begin: gen_mem
            ddr3_model u_comp_ddr3
            (
                .rst_n   (ddr3_reset_n),
                .ck      (ddr3_ck_p_sdram),
                .ck_n    (ddr3_ck_n_sdram),
                .cke     (ddr3_cke_sdram),
                .cs_n    (ddr3_cs_n_sdram[r]),
                .ras_n   (ddr3_ras_n_sdram),
                .cas_n   (ddr3_cas_n_sdram),
                .we_n    (ddr3_we_n_sdram),
                .dm_tdqs (ddr3_dm_sdram[(2*(i+1)-1):(2*i)]),
                .ba      (ddr3_ba_sdram[r]),
                .addr    (ddr3_addr_sdram[r]),
                .dq      (ddr3_dq_sdram[16*(i+1)-1:16*(i)]),
                .dqs     (ddr3_dqs_p_sdram[(2*(i+1)-1):(2*i)]),
                .dqs_n   (ddr3_dqs_n_sdram[(2*(i+1)-1):(2*i)]),
                .tdqs_n  (),
                .odt     (ddr3_odt_sdram[r])
                );
        end
        end
        if (DQ_WIDTH%16) begin: gen_mem_extrabits
        ddr3_model u_comp_ddr3
            (
            .rst_n   (ddr3_reset_n),
            .ck      (ddr3_ck_p_sdram),
            .ck_n    (ddr3_ck_n_sdram),
            .cke     (ddr3_cke_sdram[r]),
            .cs_n    (ddr3_cs_n_sdram[r]),
            .ras_n   (ddr3_ras_n_sdram),
            .cas_n   (ddr3_cas_n_sdram),
            .we_n    (ddr3_we_n_sdram),
            .dm_tdqs ({ddr3_dm_sdram[DM_WIDTH-1],ddr3_dm_sdram[DM_WIDTH-1]}),
            .ba      (ddr3_ba_sdram[r]),
            .addr    (ddr3_addr_sdram[r]),
            .dq      ({ddr3_dq_sdram[DQ_WIDTH-1:(DQ_WIDTH-8)],
                        ddr3_dq_sdram[DQ_WIDTH-1:(DQ_WIDTH-8)]}),
            .dqs     ({ddr3_dqs_p_sdram[DQS_WIDTH-1],
                        ddr3_dqs_p_sdram[DQS_WIDTH-1]}),
            .dqs_n   ({ddr3_dqs_n_sdram[DQS_WIDTH-1],
                        ddr3_dqs_n_sdram[DQS_WIDTH-1]}),
            .tdqs_n  (),
            .odt     (ddr3_odt_sdram[r])
            );
        end
    end
    endgenerate

    initial begin
        uart_tx <= 1'b1;
        @(negedge rst);

        repeat(20000) @(posedge clk);

        $finish;
    end
endmodule