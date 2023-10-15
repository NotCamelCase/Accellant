`include "defines.svh"
`include "memory_map.svh"

import defines::*;

module vga_core
(
    input logic         clk, rst,
    // IO Interconnect -> VGA
    input logic         io_bus_s_rd_en,
    input logic         io_bus_s_wr_en,
    input logic         io_bus_s_cs,
    input logic[31:0]   io_bus_s_address,
    input logic[31:0]   io_bus_s_wr_data,
    // VGA -> SoC
    output logic[31:0]  axi_awaddr,
    output logic[1:0]   axi_awburst,
    output logic[7:0]   axi_awlen,
    output logic[2:0]   axi_awsize,
    output logic        axi_awvalid,
    input logic         axi_awready,
    output logic[31:0]  axi_wdata,
    output logic[3:0]   axi_wstrb,
    output logic        axi_wlast,
    output logic        axi_wvalid,
    input logic         axi_wready,
    input logic[1:0]    axi_bresp,
    input logic         axi_bvalid,
    output logic        axi_bready,
    output logic[31:0]  axi_araddr,
    output logic[7:0]   axi_arlen,
    output logic[2:0]   axi_arsize,
    output logic[1:0]   axi_arburst,
    output logic        axi_arvalid,
    input logic         axi_arready,
    input logic[31:0]   axi_rdata,
    input logic[1:0]    axi_rresp,
    input logic         axi_rvalid,
    input logic         axi_rlast,
    output logic        axi_rready,
    // VGA inf
    output logic[3:0]   r, g, b,
    output logic        hsync, vsync,
    // LSD inf
    output logic[31:0]  flush_start_addr,
    output logic[31:0]  flush_end_addr
);
    // VGA video out timings
    localparam  HSYNC_START             = 656;
    localparam  HSYNC_END               = 752;
    localparam  HMAX                    = 800;
    localparam  VSYNC_START             = 490;
    localparam  VSYNC_END               = 492;
    localparam  VMAX                    = 525;

    // Display resolution
    localparam  FRAME_WIDTH             = 640;
    localparam  FRAME_HEIGHT            = 480;

    // How many pixels' worth of data will be buffered up
    localparam  PIXEL_FIFO_LENGTH       = 128;
    localparam  PIXEL_FIFO_BURST_SIZE   = (PIXEL_FIFO_LENGTH / 2) * 4;
    localparam  PIXEL_FIFO_BURST_LENGTH = PIXEL_FIFO_BURST_SIZE / 4;

    // How many bursts are needed a frame to fetch entire frame buffer
    localparam  BURST_CTR_MAX           = (FRAME_WIDTH * FRAME_HEIGHT * 4) / PIXEL_FIFO_BURST_SIZE;
    localparam  BURST_CTR_WIDTH         = $clog2(BURST_CTR_MAX);

    typedef enum {
        IDLE,
        ISSUE_READ_ADDRESS,
        FETCH_DATA,
        WAIT_FIFO_SPACE
    } state_t;

    logic                       clk_vga;
    logic[1:0]                  clk_div;

    // VGA clock-enable
    logic                       vga_ce;

    // Frame buffer base address from which the contents of next frame to be displayed will be fetched
    logic[31:0]                 fb_base_addr_reg;

    state_t                     state_reg;

    logic[7:0]                  pixel_r_in, pixel_g_in, pixel_b_in;

    // Counters
    logic[9:0]                  h_ctr_reg, v_ctr_reg;

    logic[BURST_CTR_WIDTH-1:0]  burst_ctr_reg;

    // Video sync signals
    logic                       hsync_reg, vsync_reg;
    logic                       video_on, vblank;

    logic[11:0]                 pixel_data;

    // RGB output
    logic[3:0]                  r_reg, g_reg, b_reg;

    // Pixel FIFO
    logic                       clear_px_fifo, px_fifo_almost_empty, px_fifo_empty;

    // VGA clock gen: 100 Mhz -> 25 Mhz
    always_ff @(posedge clk) begin
        { clk_vga, clk_div } <= clk_div + 2'b1;
    end

    // VGA registers
    always_ff @( posedge clk) begin
        if (rst)
            fb_base_addr_reg <= '0;
        else if (io_bus_s_cs && io_bus_s_wr_en) begin
            unique case (io_bus_s_address[7:0])
                MMIO_VGA_REG_SET_FB_BASE_ADDR: fb_base_addr_reg <= io_bus_s_wr_data;
                MMIO_VGA_REG_SET_FLUSH_START_ADDR: flush_start_addr <= io_bus_s_wr_data;
                MMIO_VGA_REG_SET_FLUSH_END_ADDR: flush_end_addr <= io_bus_s_wr_data;
                default: ;
            endcase
        end
    end

    assign vga_ce = clk_vga;

    true_rom #(.ROM_FILE("gamma_lut.mem"), .ADDR_WIDTH(8), .DATA_WIDTH(8), .READ_HEX("NO")) gamma_lut_r(
        .addr(axi_rdata[7:0]),
        .data(pixel_r_in));

    true_rom #(.ROM_FILE("gamma_lut.mem"), .ADDR_WIDTH(8), .DATA_WIDTH(8), .READ_HEX("NO")) gamma_lut_g(
        .addr(axi_rdata[15:8]),
        .data(pixel_g_in));

    true_rom #(.ROM_FILE("gamma_lut.mem"), .ADDR_WIDTH(8), .DATA_WIDTH(8), .READ_HEX("NO")) gamma_lut_b(
        .addr(axi_rdata[23:16]),
        .data(pixel_b_in));

    // Pixel FIFO
    basic_fifo #(.ADDR_WIDTH($clog2(PIXEL_FIFO_LENGTH)), .DATA_WIDTH(12), .ALMOST_EMPTY_THRESHOLD(PIXEL_FIFO_BURST_LENGTH - 1)) pixel_fifo(
        .clk(clk),
        .rst(rst),
        .clear(clear_px_fifo),
        .push(axi_rvalid), // Push pixel data just fetched
        .pop(vga_ce && video_on && ~px_fifo_empty),
        .empty(px_fifo_empty),
        .full(),
        .almost_empty(px_fifo_almost_empty),
        .almost_full(),
        .wr_data({pixel_b_in[7:4], pixel_g_in[7:4], pixel_r_in[7:4]}), // Compose 4-bit gamma-cuorrtec RGB triplets for VGA scanout
        .rd_data(pixel_data));

    // AXI read inf
    assign axi_arburst = 2'b01; // INCR
    assign axi_rready = 1'b1;
    assign axi_arlen = PIXEL_FIFO_BURST_LENGTH - 1; // AXI burst read length
    assign axi_arsize = 3'b010; // 32-bit read access

    // AXI write interface (unused)
    assign axi_awvalid = 1'b0;
    assign axi_awaddr = '0;
    assign axi_awlen = '0;
    assign axi_awsize = '0;
    assign axi_awburst = '0;
    assign axi_wdata = '0;
    assign axi_wvalid = 1'b0;
    assign axi_wlast = 1'b0;
    assign axi_wstrb = '0;
    assign axi_bready = 1'b1;

    assign clear_px_fifo = (state_reg == IDLE) && vblank;

    always_ff @(posedge clk) begin
        if (rst) begin
            state_reg <= IDLE;
            axi_arvalid <= 1'b0;
        end else begin
            unique case (state_reg)
                IDLE: begin
                    // Register FB base address
                    axi_araddr <= fb_base_addr_reg;

                    axi_arvalid <= 1'b0;

                    burst_ctr_reg <= BURST_CTR_MAX - 1;

                    // Wait for V-blank to fetch frame buffer data to display
                    if (vblank)
                        state_reg <= WAIT_FIFO_SPACE;
                end

                WAIT_FIFO_SPACE: begin
                    if (px_fifo_almost_empty) begin
                        axi_arvalid <= 1'b1;
                        state_reg <= ISSUE_READ_ADDRESS;
                    end
                end

                ISSUE_READ_ADDRESS: begin
                    if (axi_arready) begin
                        // Read address issued, wait up on data arrival
                        state_reg <= FETCH_DATA;
                        axi_arvalid <= 1'b0;
                    end
                end

                FETCH_DATA: begin
                    if (axi_rvalid) begin
                        if (axi_rlast) begin
                            // Increase FB fetch address for the next stream of pixels in
                            axi_araddr <= axi_araddr + 32'(PIXEL_FIFO_BURST_SIZE);

                            // Next burst
                            burst_ctr_reg <= burst_ctr_reg - BURST_CTR_WIDTH'(1);

                            if (burst_ctr_reg == '0)
                                state_reg <= IDLE; // Frame complete
                            else
                                state_reg <= WAIT_FIFO_SPACE; // Burst complete
                        end
                    end
                end

                default: ;
            endcase
        end
    end

    // VGA hsync & vsync gen
    always_ff @(posedge clk_vga) begin
        if (rst) begin
            h_ctr_reg <= '0;
            v_ctr_reg <= '0;
            hsync_reg <= 1'b1;
            vsync_reg <= 1'b1;
        end else begin
            h_ctr_reg <= (h_ctr_reg == HMAX-1) ? 0 : (h_ctr_reg + 1);
            v_ctr_reg <= (h_ctr_reg == HMAX-1) ? ((v_ctr_reg == VMAX-1) ? 0 : (v_ctr_reg + 1)) : v_ctr_reg;
            hsync_reg <= ~((h_ctr_reg >= HSYNC_START) && (h_ctr_reg < HSYNC_END));
            vsync_reg <= ~((v_ctr_reg >= VSYNC_START) && (v_ctr_reg < VSYNC_END));
        end
    end

    assign video_on = (h_ctr_reg < FRAME_WIDTH) && (v_ctr_reg < FRAME_HEIGHT);
    assign vblank = ~vsync_reg;

    // RGB
    always_ff @(posedge clk_vga) begin
        r_reg <= video_on ? pixel_data[3:0] : 4'b0;
        g_reg <= video_on ? pixel_data[7:4] : 4'b0;
        b_reg <= video_on ? pixel_data[11:8] : 4'b0;
    end

    // Outputs
    assign r = r_reg;
    assign g = g_reg;
    assign b = b_reg;
    assign hsync = hsync_reg;
    assign vsync = vsync_reg;
endmodule