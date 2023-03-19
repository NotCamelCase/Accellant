`include "defines.svh"
`include "memory_map.svh"

import defines::*;

module accellant_soc
#(LED_COUNT = 4)
(
    input logic                 clk, rst,
    input logic                 uart_tx,
    output logic                uart_rx,
    output logic[LED_COUNT-1:0] led
);
    // AXI ibus master
    logic[31:0]             axi_ibus_m_awaddr;
    logic[1:0]              axi_ibus_m_awburst;
    logic[7:0]              axi_ibus_m_awlen;
    logic[2:0]              axi_ibus_m_awsize;
    logic                   axi_ibus_m_awvalid;
    logic                   axi_ibus_m_awready;
    logic[31:0]             axi_ibus_m_wdata;
    logic[3:0]              axi_ibus_m_wstrb;
    logic                   axi_ibus_m_wlast;
    logic                   axi_ibus_m_wvalid;
    logic                   axi_ibus_m_wready;
    logic[1:0]              axi_ibus_m_bresp;
    logic                   axi_ibus_m_bvalid;
    logic                   axi_ibus_m_bready;
    logic[31:0]             axi_ibus_m_araddr;
    logic[7:0]              axi_ibus_m_arlen;
    logic[2:0]              axi_ibus_m_arsize;
    logic[1:0]              axi_ibus_m_arburst;
    logic                   axi_ibus_m_arvalid;
    logic                   axi_ibus_m_arready;
    logic[31:0]             axi_ibus_m_rdata;
    logic[1:0]              axi_ibus_m_rresp;
    logic                   axi_ibus_m_rvalid;
    logic                   axi_ibus_m_rlast;
    logic                   axi_ibus_m_rready;

    // AXI ibus slave
    logic[31:0]             axi_ibus_s_awaddr;
    logic[1:0]              axi_ibus_s_awburst;
    logic[7:0]              axi_ibus_s_awlen;
    logic[2:0]              axi_ibus_s_awsize;
    logic                   axi_ibus_s_awvalid;
    logic                   axi_ibus_s_awready;
    logic[31:0]             axi_ibus_s_wdata;
    logic[3:0]              axi_ibus_s_wstrb;
    logic                   axi_ibus_s_wlast;
    logic                   axi_ibus_s_wvalid;
    logic                   axi_ibus_s_wready;
    logic[1:0]              axi_ibus_s_bresp;
    logic                   axi_ibus_s_bvalid;
    logic                   axi_ibus_s_bready;
    logic[31:0]             axi_ibus_s_araddr;
    logic[7:0]              axi_ibus_s_arlen;
    logic[2:0]              axi_ibus_s_arsize;
    logic[1:0]              axi_ibus_s_arburst;
    logic                   axi_ibus_s_arvalid;
    logic                   axi_ibus_s_arready;
    logic[31:0]             axi_ibus_s_rdata;
    logic[1:0]              axi_ibus_s_rresp;
    logic                   axi_ibus_s_rvalid;
    logic                   axi_ibus_s_rlast;
    logic                   axi_ibus_s_rready;

    // AXI dbus master
    logic[31:0]             axi_dbus_m_awaddr;
    logic[1:0]              axi_dbus_m_awburst;
    logic[7:0]              axi_dbus_m_awlen;
    logic[2:0]              axi_dbus_m_awsize;
    logic                   axi_dbus_m_awvalid;
    logic                   axi_dbus_m_awready;
    logic[31:0]             axi_dbus_m_wdata;
    logic[3:0]              axi_dbus_m_wstrb;
    logic                   axi_dbus_m_wlast;
    logic                   axi_dbus_m_wvalid;
    logic                   axi_dbus_m_wready;
    logic[1:0]              axi_dbus_m_bresp;
    logic                   axi_dbus_m_bvalid;
    logic                   axi_dbus_m_bready;
    logic[31:0]             axi_dbus_m_araddr;
    logic[7:0]              axi_dbus_m_arlen;
    logic[2:0]              axi_dbus_m_arsize;
    logic[1:0]              axi_dbus_m_arburst;
    logic                   axi_dbus_m_arvalid;
    logic                   axi_dbus_m_arready;
    logic[31:0]             axi_dbus_m_rdata;
    logic[1:0]              axi_dbus_m_rresp;
    logic                   axi_dbus_m_rvalid;
    logic                   axi_dbus_m_rlast;
    logic                   axi_dbus_m_rready;

    // AXI dbus slave
    logic[31:0]             axi_dbus_s_awaddr;
    logic[1:0]              axi_dbus_s_awburst;
    logic[7:0]              axi_dbus_s_awlen;
    logic[2:0]              axi_dbus_s_awsize;
    logic                   axi_dbus_s_awvalid;
    logic                   axi_dbus_s_awready;
    logic[31:0]             axi_dbus_s_wdata;
    logic[3:0]              axi_dbus_s_wstrb;
    logic                   axi_dbus_s_wlast;
    logic                   axi_dbus_s_wvalid;
    logic                   axi_dbus_s_wready;
    logic[1:0]              axi_dbus_s_bresp;
    logic                   axi_dbus_s_bvalid;
    logic                   axi_dbus_s_bready;
    logic[31:0]             axi_dbus_s_araddr;
    logic[7:0]              axi_dbus_s_arlen;
    logic[2:0]              axi_dbus_s_arsize;
    logic[1:0]              axi_dbus_s_arburst;
    logic                   axi_dbus_s_arvalid;
    logic                   axi_dbus_s_arready;
    logic[31:0]             axi_dbus_s_rdata;
    logic[1:0]              axi_dbus_s_rresp;
    logic                   axi_dbus_s_rvalid;
    logic                   axi_dbus_s_rlast;
    logic                   axi_dbus_s_rready;

    // I/O bus master
    logic                   io_bus_m_rd_en;
    logic                   io_bus_m_wr_en;
    logic[NUM_IO_CORES-1:0] io_bus_m_cs;
    logic[31:0]             io_bus_m_address;
    logic[31:0]             io_bus_m_wr_data;
    logic[31:0]             io_bus_m_rd_data;

    // I/O bus slaves
    logic                   io_bus_s_rd_en;
    logic                   io_bus_s_wr_en;
    logic[NUM_IO_CORES-1:0] io_bus_s_cs;
    logic[31:0]             io_bus_s_address;
    logic[31:0]             io_bus_s_wr_data;
    // I/O bus read data
    logic[31:0]             io_bus_led_rd_data;
    logic[31:0]             io_bus_timer_rd_data;
    logic[31:0]             io_bus_uart_rd_data;

    riscv_core core(
    	.clk(clk),
        .rst(rst),
        .io_bus_rd_en(io_bus_m_rd_en),
        .io_bus_wr_en(io_bus_m_wr_en),
        .io_bus_cs(io_bus_m_cs),
        .io_bus_address(io_bus_m_address),
        .io_bus_wr_data(io_bus_m_wr_data),
        .io_bus_rd_data(io_bus_m_rd_data),
        .axi_ibus_awaddr(axi_ibus_m_awaddr),
        .axi_ibus_awburst(axi_ibus_m_awburst),
        .axi_ibus_awlen(axi_ibus_m_awlen),
        .axi_ibus_awsize(axi_ibus_m_awsize),
        .axi_ibus_awvalid(axi_ibus_m_awvalid),
        .axi_ibus_awready(axi_ibus_m_awready),
        .axi_ibus_wdata(axi_ibus_m_wdata),
        .axi_ibus_wstrb(axi_ibus_m_wstrb),
        .axi_ibus_wlast(axi_ibus_m_wlast),
        .axi_ibus_wvalid(axi_ibus_m_wvalid),
        .axi_ibus_wready(axi_ibus_m_wready),
        .axi_ibus_bresp(axi_ibus_m_bresp),
        .axi_ibus_bvalid(axi_ibus_m_bvalid),
        .axi_ibus_bready(axi_ibus_m_bready),
        .axi_ibus_araddr(axi_ibus_m_araddr),
        .axi_ibus_arlen(axi_ibus_m_arlen),
        .axi_ibus_arsize (axi_ibus_m_arsize),
        .axi_ibus_arburst(axi_ibus_m_arburst),
        .axi_ibus_arvalid(axi_ibus_m_arvalid),
        .axi_ibus_arready(axi_ibus_m_arready),
        .axi_ibus_rdata(axi_ibus_m_rdata),
        .axi_ibus_rresp(axi_ibus_m_rresp),
        .axi_ibus_rvalid(axi_ibus_m_rvalid),
        .axi_ibus_rlast(axi_ibus_m_rlast),
        .axi_ibus_rready(axi_ibus_m_rready),
        .axi_dbus_awaddr(axi_dbus_m_awaddr),
        .axi_dbus_awburst(axi_dbus_m_awburst),
        .axi_dbus_awlen(axi_dbus_m_awlen),
        .axi_dbus_awsize (axi_dbus_m_awsize),
        .axi_dbus_awvalid(axi_dbus_m_awvalid),
        .axi_dbus_awready(axi_dbus_m_awready),
        .axi_dbus_wdata(axi_dbus_m_wdata),
        .axi_dbus_wstrb(axi_dbus_m_wstrb),
        .axi_dbus_wlast(axi_dbus_m_wlast),
        .axi_dbus_wvalid(axi_dbus_m_wvalid),
        .axi_dbus_wready(axi_dbus_m_wready),
        .axi_dbus_bresp (axi_dbus_m_bresp),
        .axi_dbus_bvalid(axi_dbus_m_bvalid),
        .axi_dbus_bready(axi_dbus_m_bready),
        .axi_dbus_araddr(axi_dbus_m_araddr),
        .axi_dbus_arlen(axi_dbus_m_arlen),
        .axi_dbus_arsize (axi_dbus_m_arsize),
        .axi_dbus_arburst(axi_dbus_m_arburst),
        .axi_dbus_arvalid(axi_dbus_m_arvalid),
        .axi_dbus_arready(axi_dbus_m_arready),
        .axi_dbus_rdata(axi_dbus_m_rdata),
        .axi_dbus_rresp(axi_dbus_m_rresp),
        .axi_dbus_rvalid(axi_dbus_m_rvalid),
        .axi_dbus_rlast(axi_dbus_m_rlast),
        .axi_dbus_rready(axi_dbus_m_rready));

    io_interconnect io_xbar(
        .clk(clk),
        .rst(rst),
        .io_bus_m_rd_en(io_bus_m_rd_en),
        .io_bus_m_wr_en(io_bus_m_wr_en),
        .io_bus_m_cs(io_bus_m_cs),
        .io_bus_m_address(io_bus_m_address),
        .io_bus_m_wr_data(io_bus_m_wr_data),
        .io_bus_m_rd_data(io_bus_m_rd_data),
        .io_bus_timer_rd_data(io_bus_timer_rd_data),
        .io_bus_uart_rd_data(io_bus_uart_rd_data),
        .io_bus_s_rd_en(io_bus_s_rd_en),
        .io_bus_s_wr_en(io_bus_s_wr_en),
        .io_bus_s_cs(io_bus_s_cs),
        .io_bus_s_address(io_bus_s_address),
        .io_bus_s_wr_data(io_bus_s_wr_data));

    // Slot #0
    led_core #(.NUM_LEDS(LED_COUNT)) ledc(
        .clk(clk),
        .rst(rst),
        .led(led),
        .io_bus_s_cs(io_bus_s_cs[0]),
        .io_bus_s_rd_en(io_bus_s_rd_en),
        .io_bus_s_wr_en(io_bus_s_wr_en),
        .io_bus_s_address(io_bus_s_address),
        .io_bus_s_wr_data(io_bus_s_wr_data));

    // Slot #1
    timer_core timer(
        .clk(clk),
        .rst(rst),
        .io_bus_s_rd_en(io_bus_s_rd_en),
        .io_bus_s_cs(io_bus_s_cs[1]),
        .io_bus_s_wr_en(io_bus_s_wr_en),
        .io_bus_s_address(io_bus_s_address),
        .io_bus_s_wr_data(io_bus_s_wr_data),
        .rd_data(io_bus_timer_rd_data));

    // Slot #2
    uart_core uart(
        .clk(clk),
        .rst(rst),
        .io_bus_s_rd_en(io_bus_s_rd_en),
        .io_bus_s_wr_en(io_bus_s_wr_en),
        .io_bus_s_cs(io_bus_s_cs[2]),
        .io_bus_s_address(io_bus_s_address),
        .io_bus_s_wr_data(io_bus_s_wr_data),
        .uart_rx(uart_tx),
        .uart_tx(uart_rx),
        .rd_data(io_bus_uart_rd_data));

    axi_interconnect #(
        .S_COUNT(AXI_XBAR_NUM_SLAVES),
        .M_COUNT(AXI_XBAR_NUM_MASTERS),
        .M_REGIONS(1),
        // AXI crossbar address configuration
        .M_BASE_ADDR({INSTR_ROM_BASE_ADDRESS, RAM_BASE_ADDRESS}),
        .M_ADDR_WIDTH({$clog2(INSTR_ROM_SIZE), $clog2(RAM_SIZE)}),
        // AXI Master-Slave read/write connections
        .M_CONNECT_READ({2'b11, 2'b11}),
        .M_CONNECT_WRITE({2'b00, 2'b01})) axi_crossbar(
            .clk(clk),
            .rst(rst),
            // AXI xbar slaves
            .s_axi_awid('0),
            .s_axi_awaddr({axi_ibus_m_awaddr, axi_dbus_m_awaddr}),
            .s_axi_awlen({axi_ibus_m_awlen, axi_dbus_m_awlen}),
            .s_axi_awsize({axi_ibus_m_awsize, axi_dbus_m_awsize}),
            .s_axi_awburst({axi_ibus_m_awburst, axi_dbus_m_awburst}),
            .s_axi_awlock('0),
            .s_axi_awcache('0),
            .s_axi_awprot('0),
            .s_axi_awqos('0),
            .s_axi_awuser('0),
            .s_axi_awvalid({axi_ibus_m_awvalid, axi_dbus_m_awvalid}),
            .s_axi_awready({axi_ibus_m_awready, axi_dbus_m_awready}),
            .s_axi_wdata({axi_ibus_m_wdata, axi_dbus_m_wdata}),
            .s_axi_wstrb({axi_ibus_m_wstrb, axi_dbus_m_wstrb}),
            .s_axi_wlast({axi_ibus_m_wlast, axi_dbus_m_wlast}),
            .s_axi_wuser('0),
            .s_axi_wvalid({axi_ibus_m_wvalid, axi_dbus_m_wvalid}),
            .s_axi_wready({axi_ibus_m_wready, axi_dbus_m_wready}),
            .s_axi_bid(),
            .s_axi_bresp({axi_ibus_m_bresp, axi_dbus_m_bresp}),
            .s_axi_buser(),
            .s_axi_bvalid({axi_ibus_m_bvalid, axi_dbus_m_bvalid}),
            .s_axi_bready({axi_ibus_m_bready, axi_dbus_m_bready}),
            .s_axi_arid('0),
            .s_axi_araddr({axi_ibus_m_araddr, axi_dbus_m_araddr}),
            .s_axi_arlen({axi_ibus_m_arlen, axi_dbus_m_arlen}),
            .s_axi_arsize({axi_ibus_m_arsize, axi_dbus_m_arsize}),
            .s_axi_arburst({axi_ibus_m_arburst, axi_dbus_m_arburst}),
            .s_axi_arlock('0),
            .s_axi_arcache('0),
            .s_axi_arprot('0),
            .s_axi_arqos('0),
            .s_axi_aruser('0),
            .s_axi_arvalid({axi_ibus_m_arvalid, axi_dbus_m_arvalid}),
            .s_axi_arready({axi_ibus_m_arready, axi_dbus_m_arready}),
            .s_axi_rid(),
            .s_axi_rdata({axi_ibus_m_rdata, axi_dbus_m_rdata}),
            .s_axi_rresp({axi_ibus_m_rresp, axi_dbus_m_rresp}),
            .s_axi_rlast({axi_ibus_m_rlast, axi_dbus_m_rlast}),
            .s_axi_ruser(),
            .s_axi_rvalid({axi_ibus_m_rvalid, axi_dbus_m_rvalid}),
            .s_axi_rready({axi_ibus_m_rready, axi_dbus_m_rready}),
            // AXI xbar masters
            .m_axi_awid(),
            .m_axi_awaddr({axi_ibus_s_awaddr, axi_dbus_s_awaddr}),
            .m_axi_awlen({axi_ibus_s_awlen, axi_dbus_s_awlen}),
            .m_axi_awsize({axi_ibus_s_awsize, axi_dbus_s_awsize}),
            .m_axi_awburst({axi_ibus_s_awburst, axi_dbus_s_awburst}),
            .m_axi_awlock(),
            .m_axi_awcache(),
            .m_axi_awprot(),
            .m_axi_awqos(),
            .m_axi_awuser(),
            .m_axi_awvalid({axi_ibus_s_awvalid, axi_dbus_s_awvalid}),
            .m_axi_awready({axi_ibus_s_awready, axi_dbus_s_awready}),
            .m_axi_wdata({axi_ibus_s_wdata, axi_dbus_s_wdata}),
            .m_axi_wstrb({axi_ibus_s_wstrb, axi_dbus_s_wstrb}),
            .m_axi_wlast({axi_ibus_s_wlast, axi_dbus_s_wlast}),
            .m_axi_wuser(),
            .m_axi_wvalid({axi_ibus_s_wvalid, axi_dbus_s_wvalid}),
            .m_axi_wready({axi_ibus_s_wready, axi_dbus_s_wready}),
            .m_axi_bid(),
            .m_axi_bresp({axi_ibus_s_bresp, axi_dbus_s_bresp}),
            .m_axi_buser(),
            .m_axi_bvalid({axi_ibus_s_bvalid, axi_dbus_s_bvalid}),
            .m_axi_bready({axi_ibus_s_bready, axi_dbus_s_bready}),
            .m_axi_arid(),
            .m_axi_araddr({axi_ibus_s_araddr, axi_dbus_s_araddr}),
            .m_axi_arlen({axi_ibus_s_arlen, axi_dbus_s_arlen}),
            .m_axi_arsize({axi_ibus_s_arsize, axi_dbus_s_arsize}),
            .m_axi_arburst({axi_ibus_s_arburst, axi_dbus_s_arburst}),
            .m_axi_arlock(),
            .m_axi_arcache(),
            .m_axi_arprot(),
            .m_axi_arqos(),
            .m_axi_aruser(),
            .m_axi_arvalid({axi_ibus_s_arvalid, axi_dbus_s_arvalid}),
            .m_axi_arready({axi_ibus_s_arready, axi_dbus_s_arready}),
            .m_axi_rid(),
            .m_axi_rdata({axi_ibus_s_rdata, axi_dbus_s_rdata}),
            .m_axi_rresp({axi_ibus_s_rresp, axi_dbus_s_rresp}),
            .m_axi_rlast({axi_ibus_s_rlast, axi_dbus_s_rlast}),
            .m_axi_ruser(),
            .m_axi_rvalid({axi_ibus_s_rvalid, axi_dbus_s_rvalid}),
            .m_axi_rready({axi_ibus_s_rready, axi_dbus_s_rready}));

    // AXI BRAM ROM
    instruction_rom boot_rom(
        .clk(clk),
        .rst(~rst), // Active-low sync AXI reset
        .axi_awid('0),
        .axi_awaddr(axi_ibus_s_awaddr),
        .axi_awlen(axi_ibus_s_awlen),
        .axi_awsize(axi_ibus_s_awsize),
        .axi_awburst(axi_ibus_s_awburst),
        .axi_awvalid(axi_ibus_s_awvalid),
        .axi_awready(axi_ibus_s_awready),
        .axi_wdata(axi_ibus_s_wdata),
        .axi_wstrb(axi_ibus_s_wstrb),
        .axi_wlast(axi_ibus_s_wlast),
        .axi_wvalid(axi_ibus_s_wvalid),
        .axi_wready(axi_ibus_s_wready),
        .axi_bid(),
        .axi_bresp(axi_ibus_s_bresp),
        .axi_bvalid(axi_ibus_s_bvalid),
        .axi_bready(axi_ibus_s_bready),
        .axi_arid('0),
        .axi_araddr(axi_ibus_s_araddr),
        .axi_arlen(axi_ibus_s_arlen),
        .axi_arsize(axi_ibus_s_arsize),
        .axi_arburst(axi_ibus_s_arburst),
        .axi_arvalid(axi_ibus_s_arvalid),
        .axi_arready(axi_ibus_s_arready),
        .axi_rid(),
        .axi_rdata(axi_ibus_s_rdata),
        .axi_rresp(axi_ibus_s_rresp),
        .axi_rlast(axi_ibus_s_rlast),
        .axi_rvalid(axi_ibus_s_rvalid),
        .axi_rready(axi_ibus_s_rready));

    // AXI BRAM RAM
    data_ram ram(
        .s_aclk(clk),
        .s_aresetn(~rst), // Active-low sync AXI reset
        .s_axi_awid('0),
        .s_axi_awaddr(axi_dbus_s_awaddr),
        .s_axi_awlen(axi_dbus_s_awlen),
        .s_axi_awsize(axi_dbus_s_awsize),
        .s_axi_awburst(axi_dbus_s_awburst),
        .s_axi_awvalid(axi_dbus_s_awvalid),
        .s_axi_awready(axi_dbus_s_awready),
        .s_axi_wdata(axi_dbus_s_wdata),
        .s_axi_wstrb(axi_dbus_s_wstrb),
        .s_axi_wlast(axi_dbus_s_wlast),
        .s_axi_wvalid(axi_dbus_s_wvalid),
        .s_axi_wready(axi_dbus_s_wready),
        .s_axi_bid(),
        .s_axi_bresp(axi_dbus_s_bresp),
        .s_axi_bvalid(axi_dbus_s_bvalid),
        .s_axi_bready(axi_dbus_s_bready),
        .s_axi_arid('0),
        .s_axi_araddr(axi_dbus_s_araddr),
        .s_axi_arlen(axi_dbus_s_arlen),
        .s_axi_arsize(axi_dbus_s_arsize),
        .s_axi_arburst(axi_dbus_s_arburst),
        .s_axi_arvalid(axi_dbus_s_arvalid),
        .s_axi_arready(axi_dbus_s_arready),
        .s_axi_rid(),
        .s_axi_rdata(axi_dbus_s_rdata),
        .s_axi_rresp(axi_dbus_s_rresp),
        .s_axi_rlast(axi_dbus_s_rlast),
        .s_axi_rvalid(axi_dbus_s_rvalid),
        .s_axi_rready(axi_dbus_s_rready));
endmodule