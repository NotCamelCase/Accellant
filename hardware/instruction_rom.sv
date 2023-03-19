// Sync ROM w/ AXI4 interface that only supports 32-bit INCR read burst accesses
module instruction_rom
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
    localparam  INSTR_ROM_SIZE  = 1024; // 1KB
    localparam  INSTR_ROM_DEPTH = $clog2(INSTR_ROM_SIZE);

    typedef enum {
        IDLE,
        START_BURST,
        READ_BURST
    } state_t;

    state_t                     state_reg;

    logic                       ar_ready_reg;
    logic[31:0]                 ar_addr_reg, ar_addr_nxt;
    logic[7:0]                  ar_len_reg;

    logic                       rd_valid_reg;
    logic                       rd_last_reg;

    // Sync ROM backing the instruction ROM
    sync_rom #(.ROM_FILE("boot.mem"), .READ_HEX("YES"), .ADDR_WIDTH(INSTR_ROM_DEPTH), .DATA_WIDTH(32)) rom(
        .clk(clk),
        .addr((axi_rready && axi_rvalid) ? ar_addr_nxt[INSTR_ROM_DEPTH-1:0] : ar_addr_reg[INSTR_ROM_DEPTH-1:0]),
        .data(axi_rdata));

    // Increment by 1 because sync_rom data is word-addressed
    assign ar_addr_nxt = ar_addr_reg + 32'h1;

    always_ff @(posedge clk) begin
        if (~rst) begin
            ar_ready_reg <= 1'b0;
            rd_valid_reg <= 1'b0;
            rd_last_reg <= 1'b0;
        end else begin
            unique case (state_reg)
                IDLE: begin
                    // Asserted so long as we have no read requests
                    ar_ready_reg <= 1'b1;

                    ar_len_reg <= axi_arlen;
                    ar_addr_reg <= axi_araddr >> 2;

                    // Read address transfer is complete, start bursting read data
                    if (axi_arvalid) begin
                        // De-assert arready to signal we can't accept any more read addresses
                        ar_ready_reg <= 1'b0;
                        state_reg <= START_BURST;
                    end
                end

                START_BURST: begin
                    rd_valid_reg <= 1'b1;
                    state_reg <= READ_BURST;
                end

                READ_BURST: begin
                    if (axi_rready) begin
                        ar_addr_reg <= ar_addr_nxt;
                        ar_len_reg <= ar_len_reg - 8'h1;

                        if (ar_len_reg == 8'h0) begin
                            rd_valid_reg <= 1'b0;
                            rd_last_reg <= 1'b0;
                            state_reg <= IDLE; // End of burst
                        end else if (ar_len_reg == 8'h1) begin
                            rd_last_reg <= 1'b1; // Last read cycle
                        end
                    end
                end
            endcase
        end
    end

       // Unused AXI inf
    assign axi_awready = 1'b0;
    assign axi_wready = 1'b0;
    assign axi_bvalid = 1'b0;
    assign axi_bid = '0;
    assign axi_rresp = '0;
    assign axi_rid = '0;

    // Outputs
    assign axi_arready = ar_ready_reg;
    assign axi_rvalid = rd_valid_reg;
    assign axi_rlast = rd_last_reg;
endmodule