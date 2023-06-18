// Sync RAM w/ AXI4 interface that only supports 32-bit INCR read & write burst accesses
module data_ram
(
    input logic         clk,
    input logic         rst,
    input logic         axi_awid,
    input logic[31:0]   axi_awaddr,
    input logic[7:0]    axi_awlen,
    input logic[2:0]    axi_awsize,
    input logic[1:0]    axi_awburst,
    input logic         axi_awvalid,
    output logic        axi_awready,
    input logic[31:0]   axi_wdata,
    input logic[3:0]    axi_wstrb,
    input logic         axi_wlast,
    input logic         axi_wvalid,
    output logic        axi_wready,
    output logic[0:0]   axi_bid,
    output logic[1:0]   axi_bresp,
    output logic        axi_bvalid,
    input logic         axi_bready,
    input logic         axi_arid,
    input logic[31:0]   axi_araddr,
    input logic[7:0]    axi_arlen,
    input logic[2:0]    axi_arsize,
    input logic[1:0]    axi_arburst,
    input logic         axi_arvalid,
    output logic        axi_arready,
    output logic        axi_rid,
    output logic[31:0]  axi_rdata,
    output logic[1:0]   axi_rresp,
    output logic        axi_rlast,
    output logic        axi_rvalid,
    input logic         axi_rready
);
`ifdef XILINX_SIMULATOR
    localparam  RAM_SIZE    = 32'h10000000; // 256 MB (for simulation)
`else
    localparam  RAM_SIZE    = 32'h10000; // 64 KB (for FPGA)
`endif

    localparam  RAM_DEPTH  = $clog2(RAM_SIZE);

    typedef enum {
        READ_IDLE,
        READ_START,
        READ_BURST
    } read_state_t;

    typedef enum {
        WRITE_IDLE,
        WRITE_START,
        WRITE_BURST
    } write_state_t;

    read_state_t    read_state_reg;
    write_state_t   write_state_reg;

    logic           ar_ready_reg;
    logic[31:0]     ar_addr_reg, ar_addr_nxt;
    logic[7:0]      ar_len_reg;

    logic           aw_ready_reg, w_ready_reg;
    logic[31:0]     aw_addr_reg, aw_addr_nxt;

    logic           rd_valid_reg;
    logic           rd_last_reg;

    bram_1r1w #(.ADDR_WIDTH(RAM_DEPTH), .DATA_WIDTH(32), .RAM_FILE("app.mem")) ram(
        .clk(clk),
        .wr_en(axi_wvalid && axi_wready),
        .rd_en(1'b1),
        .rd_addr((axi_rvalid && axi_rready) ? ar_addr_nxt[RAM_DEPTH-1:0] : ar_addr_reg[RAM_DEPTH-1:0]),
        .wr_addr(aw_addr_reg[RAM_DEPTH-1:0]),
        .wr_data(axi_wdata),
        .rd_data(axi_rdata));

    // Increment by 1 because sync_rom data is word-addressed
    assign ar_addr_nxt = ar_addr_reg + 32'h1;
    assign aw_addr_nxt = aw_addr_reg + 32'h1;

    // Write FSM
    always_ff @(posedge clk) begin
        if (~rst) begin
            write_state_reg <= WRITE_IDLE;
            aw_ready_reg <= 1'b0;
            w_ready_reg <= 1'b0;
        end else begin
            unique case (write_state_reg)
                WRITE_IDLE: begin
                    // Asserted so long as we have no requests
                    aw_ready_reg <= 1'b1;

                    aw_addr_reg <= axi_awaddr >> 2;

                    if (axi_awvalid) begin
                        aw_ready_reg <= 1'b0;
                        write_state_reg <= WRITE_START;
                    end
                end

                WRITE_START: begin
                    w_ready_reg <= 1'b1;
                    write_state_reg <= WRITE_BURST;
                end

                WRITE_BURST: begin
                    if (axi_wvalid) begin
                        aw_addr_reg <= aw_addr_nxt;

                        if (axi_wlast) begin
                            w_ready_reg <= 1'b0;
                            write_state_reg <= WRITE_IDLE;
                        end
                    end
                end
            endcase
        end
    end

    // Read FSM
    always_ff @(posedge clk) begin
        if (~rst) begin
            ar_ready_reg <= 1'b0;
            rd_valid_reg <= 1'b0;
            rd_last_reg <= 1'b0;
        end else begin
            unique case (read_state_reg)
                READ_IDLE: begin
                    // Asserted so long as we have no read requests
                    ar_ready_reg <= 1'b1;

                    ar_len_reg <= axi_arlen;
                    ar_addr_reg <= axi_araddr >> 2;

                    // Read address transfer is complete, start bursting read data
                    if (axi_arvalid) begin
                        // De-assert arready to signal we can't accept any more read addresses
                        ar_ready_reg <= 1'b0;
                        read_state_reg <= READ_START;
                    end
                end

                READ_START: begin
                    rd_valid_reg <= 1'b1;
                    read_state_reg <= READ_BURST;
                end

                READ_BURST: begin
                    if (axi_rready) begin
                        ar_addr_reg <= ar_addr_nxt;
                        ar_len_reg <= ar_len_reg - 8'h1;

                        if (ar_len_reg == 8'h0) begin
                            rd_valid_reg <= 1'b0;
                            rd_last_reg <= 1'b0;
                            read_state_reg <= READ_IDLE; // End of burst
                        end else if (ar_len_reg == 8'h1) begin
                            rd_last_reg <= 1'b1; // Last read cycle
                        end
                    end
                end
            endcase
        end
    end

    // Unused AXI inf
    assign axi_bvalid = 1'b1;
    assign axi_bid = '0;
    assign axi_rresp = '0;
    assign axi_rid = '0;

    // Outputs
    assign axi_awready = aw_ready_reg;
    assign axi_wready = w_ready_reg;
    assign axi_arready = ar_ready_reg;
    assign axi_rvalid = rd_valid_reg;
    assign axi_rlast = rd_last_reg;
endmodule