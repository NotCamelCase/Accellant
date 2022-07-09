`include "defines.svh"

module instruction_fetch_data
(
    input logic             clk, rst,
    // From Core
    input logic             stall,
    input logic             flush,
    // To Core
    output logic            icache_busy,
    // From IFT
    input ift_ifd_inf_t     ift_ifd_inf,
    // To IFT
    output ifd_ift_inf_t    ifd_ift_inf,
    // To ID
    output ifd_id_inf_t     ifd_id_inf
);
    localparam              CL_DATA_WIDTH           = ICACHE_CL_SIZE * 8; // CL size in bits
    localparam              CL_NUM_WORDS            = CL_DATA_WIDTH / 32; // CL size in WORDs
    localparam              CL_FETCH_BITS           = $clog2(CL_NUM_WORDS);

    typedef enum {
        IDLE,
        ISSUE_ADDRESS,
        FETCH_DATA,
        FILL_CL
    } cache_state_t;

    logic                               input_valid;
    logic[CL_DATA_WIDTH-1:0]            fetched_cache_lines;

    logic                               cache_hit, cache_miss;
    logic[ICACHE_NUM_WAY_BITS-1:0]      hit_way_idx;
    logic[ICACHE_NUM_WAYS-1:0]          way_hit_bits;
    logic[ICACHE_NUM_WAYS-1:0]          replace_way_en;

    logic[ICACHE_NUM_BLOCK_BITS-1-2:0]  pc_block_idx_reg;
    logic[ICACHE_NUM_WAY_BITS-1:0]      way_replacement_reg;

    // State machine
    logic                               icache_busy_reg;
    logic                               update_tag_en_reg;
    cache_state_t                       state_reg;
    logic[CL_FETCH_BITS-1:0]            cache_fetch_ctr_reg;
    instr_pc_t                          pc_to_fetch_reg;
    logic[CL_DATA_WIDTH-1:0]            fetched_words_reg;

    // AXI interface
    logic                               axi_awid;
    logic[31:0]                         axi_awaddr;
    logic[7:0]                          axi_awlen;
    logic[2:0]                          axi_awsize;
    logic[1:0]                          axi_awburst;
    logic                               axi_awvalid;
    logic                               axi_awready;
    logic[31:0]                         axi_wdata;
    logic[3:0]                          axi_wstrb;
    logic                               axi_wlast;
    logic                               axi_wvalid;
    logic                               axi_wready;
    logic                               axi_bid;
    logic[1:0]                          axi_bresp;
    logic                               axi_bvalid;
    logic                               axi_bready;
    logic                               axi_arid;
    logic[31:0]                         axi_araddr;
    logic[7:0]                          axi_arlen;
    logic[2:0]                          axi_arsize;
    logic[1:0]                          axi_arburst;
    logic                               axi_arvalid;
    logic                               axi_arready;
    logic                               axi_rid;
    logic[31:0]                         axi_rdata;
    logic[1:0]                          axi_rresp;
    logic                               axi_rlast;
    logic                               axi_rvalid;
    logic                               axi_rready;

    // AXI BRAM ROM
    instruction_rom rom(
        .s_aclk(clk),
        .s_aresetn(~rst), // Active-low sync AXI reset
        .s_axi_awid(axi_awid),
        .s_axi_awaddr(axi_awaddr),
        .s_axi_awlen(axi_awlen),
        .s_axi_awsize(axi_awsize),
        .s_axi_awburst(axi_awburst),
        .s_axi_awvalid(axi_awvalid),
        .s_axi_awready(axi_awready),
        .s_axi_wdata(axi_wdata),
        .s_axi_wstrb(axi_wstrb),
        .s_axi_wlast(axi_wlast),
        .s_axi_wvalid(axi_wvalid),
        .s_axi_wready(axi_wready),
        .s_axi_bid(axi_bid),
        .s_axi_bresp(axi_bresp),
        .s_axi_bvalid(axi_bvalid),
        .s_axi_bready(axi_bready),
        .s_axi_arid(axi_arid),
        .s_axi_araddr(axi_araddr),
        .s_axi_arlen(axi_arlen),
        .s_axi_arsize(axi_arsize),
        .s_axi_arburst(axi_arburst),
        .s_axi_arvalid(axi_arvalid),
        .s_axi_arready(axi_arready),
        .s_axi_rid(axi_rid),
        .s_axi_rdata(axi_rdata),
        .s_axi_rresp(axi_rresp),
        .s_axi_rlast(axi_rlast),
        .s_axi_rvalid(axi_rvalid),
        .s_axi_rready(axi_rready));

    //TODO: Need ability to abort processing cache misses in not-taken paths and roll back PC correctly!

    // Cache fetch state machine
    always_ff @(posedge clk) begin
        if (rst) begin
            state_reg <= IDLE;
            icache_busy_reg <= `FALSE;
            axi_arvalid <= `FALSE;
            update_tag_en_reg <= `FALSE;
        end else begin
            unique case (state_reg)
                IDLE: begin
                    icache_busy_reg <= `FALSE;

                    // Register current PC to fetch CL from, which is always WORD-aligned
                    pc_to_fetch_reg <= ift_ifd_inf.fetched_pc;

                    if (cache_miss) begin
                        // I$ miss, stall the CPU and switch to ISSUE_ADDRESS to send PC address
                        state_reg <= ISSUE_ADDRESS;
                        icache_busy_reg <= `TRUE;

                        // Issue AXI read address
                        axi_arvalid <= `TRUE;
                    end
                end

                ISSUE_ADDRESS: begin
                    cache_fetch_ctr_reg <= '0;

                    if (axi_arready) begin
                        // Read address is OK, wait up on data arrival
                        state_reg <= FETCH_DATA;
                        axi_arvalid <= `FALSE;
                    end
                end

                FETCH_DATA: begin
                    if (axi_rvalid) begin
                        cache_fetch_ctr_reg <= cache_fetch_ctr_reg + CL_FETCH_BITS'(1);

                        // Check if last data read has arrived
                        if (axi_rlast) begin
                            state_reg <= FILL_CL; // Data fetch is done, replace fresh CL data and inform IFT
                            update_tag_en_reg <= `TRUE;
                        end
                    end
                end

                FILL_CL: begin
                    state_reg <= IDLE;
                    update_tag_en_reg <= `FALSE;
                end
            endcase
        end
    end

    // AXI read interface
    assign axi_araddr = 32'(pc_to_fetch_reg);
    assign axi_arburst = 2'b01; // INCR
    assign axi_arid = '0;
    assign axi_arlen = CL_NUM_WORDS - 1; // AXI read burst length
    assign axi_arsize = 3'b010; // 32-bit read access
    assign axi_rready = `TRUE;

    // AXI unused interface
    assign axi_awvalid = `FALSE;
    assign axi_awaddr = '0;
    assign axi_awlen = '0;
    assign axi_awsize = '0;
    assign axi_awburst = '0;
    assign axi_wdata = '0;
    assign axi_wvalid = `FALSE;
    assign axi_wlast = `FALSE;
    assign axi_wstrb = '0;
    assign axi_awid = '0;
    assign axi_bready = `FALSE;

    // Register fetched data
    always_ff @(posedge clk) fetched_words_reg[cache_fetch_ctr_reg*32 +: 32] <= axi_rdata;

    // Counter to randomly select which way to replace upon new CL placement
    always_ff @(posedge clk) begin
        if (rst)
            way_replacement_reg <= '0;
        else if (input_valid)
            way_replacement_reg <= way_replacement_reg + ICACHE_NUM_WAY_BITS'(1);
    end

    // Convert selected way from binary to index
    always_comb begin
        //TODO: Utilize CL valid bits from IFT to make a more informed decision on which way to replace
        replace_way_en = {ICACHE_NUM_WAYS{1'b0}};
        replace_way_en[way_replacement_reg] = 1'b1;
    end

    // IFD -> IFT feedback to update CL tag & valid bit
    assign ifd_ift_inf.cache_miss = cache_miss;
    assign ifd_ift_inf.update_tag_en = replace_way_en & {ICACHE_NUM_WAYS{update_tag_en_reg}};
    assign ifd_ift_inf.update_tag_set = pc_to_fetch_reg.set_idx;
    assign ifd_ift_inf.update_tag = pc_to_fetch_reg.tag_idx;

    always_ff @(posedge clk) begin
        if (!stall)
            pc_block_idx_reg <= ift_ifd_inf.fetched_pc.block_idx[ICACHE_NUM_BLOCK_BITS-1:2]; // Byte-offset ignored
    end

    assign input_valid = ift_ifd_inf.ctrl.instruction_valid & ~(stall | flush);

    // CL data
    bram_1r1w #(.ADDR_WIDTH(ICACHE_NUM_SET_BITS + ICACHE_NUM_WAY_BITS), .DATA_WIDTH(CL_DATA_WIDTH)) cache_lines(
        .clk(clk),
        .wr_en(update_tag_en_reg),
        .rd_addr({hit_way_idx, ift_ifd_inf.fetched_pc.set_idx}),
        .wr_addr({way_replacement_reg, pc_to_fetch_reg.set_idx}),
        .wr_data(fetched_words_reg),
        .rd_data(fetched_cache_lines));

    // Compare CL tags read in IFT and determine cache hit/miss based on valid bit
    generate;
        for (genvar way_idx = 0; way_idx < ICACHE_NUM_WAYS; way_idx++)
            assign way_hit_bits[way_idx] = ift_ifd_inf.valid_bits[way_idx] && (ift_ifd_inf.tags_read[way_idx] == ift_ifd_inf.fetched_pc.tag_idx);
    endgenerate

    // Cache hit occurs if there was a tag match on a valid CL
    assign cache_hit = |way_hit_bits;

    // Cache miss occurs when no valid CL had its tag matched during a cycle input was valid
    assign cache_miss = input_valid & (~cache_hit);

    // Convert hit way index to binary
    always_comb begin
        hit_way_idx = '0;

        for (int index = 0; index < ICACHE_NUM_WAYS; index++) begin
            if (way_hit_bits[index])
                hit_way_idx |= index[ICACHE_NUM_WAY_BITS-1:0];
        end
    end

    // Control signals to ID
    always_ff @(posedge clk) begin
        if (flush)
            ifd_id_inf.ctrl.instruction_valid <= `FALSE;
        else if (!stall)
            ifd_id_inf.ctrl.instruction_valid <= input_valid & cache_hit;
    end

    always_ff @(posedge clk) begin
        if (!stall) begin
            ifd_id_inf.pc <= 32'(ift_ifd_inf.fetched_pc);
            ifd_id_inf.pc_inc <= 32'(ift_ifd_inf.fetched_pc) + 32'h4; // PC+4
        end
    end

    assign ifd_id_inf.instr = fetched_cache_lines[pc_block_idx_reg*32 +: 32]; // Deliver instruction MUX'ed by cache block index to ID

    assign icache_busy = icache_busy_reg;
endmodule