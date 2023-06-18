`include "defines.svh"

import defines::*;

module instruction_fetch_data
(
    input logic             clk, rst,
    // WB -> IFT
    input logic             wb_do_branch,
    input logic[31:0]       wb_branch_target,
    // IFT -> IFD
    input logic             ift_valid,
    input ift_ifd_inf_t     ift_ifd_inf,
    // IFD -> Core
    output logic[31:0]      axi_ibus_awaddr,
    output logic[1:0]       axi_ibus_awburst,
    output logic[7:0]       axi_ibus_awlen,
    output logic[2:0]       axi_ibus_awsize,
    output logic            axi_ibus_awvalid,
    input logic             axi_ibus_awready,
    output logic[31:0]      axi_ibus_wdata,
    output logic[3:0]       axi_ibus_wstrb,
    output logic            axi_ibus_wlast,
    output logic            axi_ibus_wvalid,
    input logic             axi_ibus_wready,
    input logic[1:0]        axi_ibus_bresp,
    input logic             axi_ibus_bvalid,
    output logic            axi_ibus_bready,
    output logic[31:0]      axi_ibus_araddr,
    output logic[7:0]       axi_ibus_arlen,
    output logic[2:0]       axi_ibus_arsize,
    output logic[1:0]       axi_ibus_arburst,
    output logic            axi_ibus_arvalid,
    input logic             axi_ibus_arready,
    input logic[31:0]       axi_ibus_rdata,
    input logic[1:0]        axi_ibus_rresp,
    input logic             axi_ibus_rvalid,
    input logic             axi_ibus_rlast,
    output logic            axi_ibus_rready,
    // IFD -> IFT
    output ifd_ift_inf_t    ifd_ift_inf,
    // IFD -> ID
    output logic            ifd_valid,
    output ifd_id_inf_t     ifd_id_inf
);
    localparam  CL_DATA_WIDTH   = ICACHE_CL_SIZE * 8; // CL size in bits
    localparam  CL_NUM_WORDS    = CL_DATA_WIDTH / 32; // CL size in WORDs
    localparam  CL_SIZE_BITS    = $clog2(ICACHE_CL_SIZE);
    localparam  CL_FETCH_BITS   = $clog2(CL_NUM_WORDS);

    typedef enum {
        IDLE,
        ISSUE_ADDRESS,
        FETCH_DATA,
        REFILL_CL
    } cache_state_t;

    logic[CL_DATA_WIDTH-1:0]            fetched_cache_line;

    logic                               cache_hit, cache_miss;
    logic[ICACHE_NUM_WAY_BITS-1:0]      hit_way_idx;
    logic[ICACHE_NUM_WAYS-1:0]          way_hit_bits;
    logic[ICACHE_NUM_WAYS-1:0]          replace_way_en;

    logic[ICACHE_NUM_BLOCK_BITS-1-2:0]  pc_block_idx_reg;
    logic[ICACHE_NUM_WAY_BITS-1:0]      way_replacement_reg;

    // State machine
    logic                               update_tag_en_reg, fetch_resume_reg;
    cache_state_t                       state_reg;
    logic[CL_FETCH_BITS-1:0]            cache_fetch_ctr_reg;
    ifu_address_t                       pc_to_fetch_reg;
    logic[CL_DATA_WIDTH-1:0]            fetched_words_reg;

    logic                               pending_branch_reg;
    logic[31:0]                         pending_branch_target_reg;

    // Handle branch misprediction during cache miss
    always_ff @(posedge clk) begin
        if (wb_do_branch)
            pending_branch_reg <= 1'b1;
        else if ((state_reg == IDLE) || (ift_valid && cache_hit))
            pending_branch_reg <= 1'b0;
    end

    always_ff @(posedge clk) if (wb_do_branch) pending_branch_target_reg <= wb_branch_target;

    // AXI read interface
    assign axi_ibus_araddr = {pc_to_fetch_reg[31:CL_SIZE_BITS], {CL_SIZE_BITS{1'b0}}};
    assign axi_ibus_arburst = 2'b01; // INCR
    assign axi_ibus_arlen = CL_NUM_WORDS - 1; // AXI read burst length
    assign axi_ibus_arsize = 3'b010; // 32-bit read access
    assign axi_ibus_rready = 1'b1;

    // Cache fetch state machine
    always_ff @(posedge clk) begin
        if (rst) begin
            state_reg <= IDLE;
            axi_ibus_arvalid <= 1'b0;
            update_tag_en_reg <= 1'b0;
            fetch_resume_reg <= 1'b0;
        end else begin
            unique case (state_reg)
                IDLE: begin
                    // Register current PC to fetch CL from, which is always WORD-aligned
                    pc_to_fetch_reg <= pending_branch_reg ? pending_branch_target_reg : ift_ifd_inf.fetched_pc;

                    fetch_resume_reg <= 1'b0;

                    if (cache_miss) begin
                        // I$ miss, stall the CPU and switch to ISSUE_ADDRESS to send PC address
                        state_reg <= ISSUE_ADDRESS;

                        // Issue AXI read address
                        axi_ibus_arvalid <= 1'b1;
                    end
                end

                ISSUE_ADDRESS: begin
                    cache_fetch_ctr_reg <= '0;

                    if (axi_ibus_arready) begin
                        // Read address is OK, wait up on data arrival
                        state_reg <= FETCH_DATA;
                        axi_ibus_arvalid <= 1'b0;
                    end
                end

                FETCH_DATA: begin
                    if (axi_ibus_rvalid) begin
                        cache_fetch_ctr_reg <= cache_fetch_ctr_reg + CL_FETCH_BITS'(1);

                        // Check if last data read has arrived
                        if (axi_ibus_rlast) begin
                            state_reg <= REFILL_CL; // Data fetch is done, replace fresh CL data and inform IFT
                            update_tag_en_reg <= 1'b1;
                        end
                    end
                end

                REFILL_CL: begin
                    update_tag_en_reg <= 1'b0;
                    fetch_resume_reg <= 1'b1; // Resume IF one cycle after CL has been re-filled

                    state_reg <= IDLE;
                end
            endcase
        end
    end

    // AXI write interface (unused)
    assign axi_ibus_awvalid = 1'b0;
    assign axi_ibus_awaddr = '0;
    assign axi_ibus_awlen = '0;
    assign axi_ibus_awsize = '0;
    assign axi_ibus_awburst = '0;
    assign axi_ibus_wdata = '0;
    assign axi_ibus_wvalid = 1'b0;
    assign axi_ibus_wlast = 1'b0;
    assign axi_ibus_wstrb = '0;
    assign axi_ibus_bready = 1'b1;

    // Register fetched data
    always_ff @(posedge clk) if (axi_ibus_rvalid) fetched_words_reg[cache_fetch_ctr_reg*32 +: 32] <= axi_ibus_rdata;

    // Simple round-robin counter to select CL way replacement
    always_ff @(posedge clk) begin
        if (rst)
            way_replacement_reg <= '0;
        else if (update_tag_en_reg)
            way_replacement_reg <= way_replacement_reg + ICACHE_NUM_WAY_BITS'(1);
    end

    // Convert selected way from binary to index
    always_comb begin
        replace_way_en = {ICACHE_NUM_WAYS{1'b0}};
        replace_way_en[way_replacement_reg] = 1'b1;
    end

    // IFD -> IFT feedback to update CL tag & valid bit
    assign ifd_ift_inf.cache_miss = cache_miss;
    assign ifd_ift_inf.resume_fetch = fetch_resume_reg;
    assign ifd_ift_inf.update_tag_en = replace_way_en & {ICACHE_NUM_WAYS{update_tag_en_reg}};
    assign ifd_ift_inf.update_tag_set = pc_to_fetch_reg.set_idx;
    assign ifd_ift_inf.update_tag = pc_to_fetch_reg.tag_idx;

    always_ff @(posedge clk) pc_block_idx_reg <= ift_ifd_inf.fetched_pc.block_idx[ICACHE_NUM_BLOCK_BITS-1:2]; // Byte-offset ignored

    // CL data
    bram_1r1w #(.ADDR_WIDTH(ICACHE_NUM_SET_BITS + ICACHE_NUM_WAY_BITS), .DATA_WIDTH(CL_DATA_WIDTH)) cache_lines(
        .clk(clk),
        .wr_en(update_tag_en_reg),
        .rd_en(ift_valid),
        .rd_addr({hit_way_idx, ift_ifd_inf.fetched_pc.set_idx}),
        .wr_addr({way_replacement_reg, pc_to_fetch_reg.set_idx}),
        .wr_data(fetched_words_reg),
        .rd_data(fetched_cache_line));

    // Compare CL tags read in IFT and determine cache hit/miss based on valid bit
    generate;
        for (genvar way_idx = 0; way_idx < ICACHE_NUM_WAYS; way_idx++)
            assign way_hit_bits[way_idx] = ift_ifd_inf.valid_bits[way_idx] && (ift_ifd_inf.tags_read[way_idx] == ift_ifd_inf.fetched_pc.tag_idx);
    endgenerate

    // Cache hit occurs if there was a tag match on a valid CL
    assign cache_hit = |way_hit_bits;

    // Cache miss occurs when no valid CL had its tag matched during a cycle that the input was valid
    assign cache_miss = ift_valid && !wb_do_branch && !cache_hit;

    // Convert hit way index to binary
    always_comb begin
        hit_way_idx = '0;

        for (int index = 0; index < ICACHE_NUM_WAYS; index++) begin
            if (way_hit_bits[index])
                hit_way_idx |= index[ICACHE_NUM_WAY_BITS-1:0];
        end
    end

    always_ff @(posedge clk) begin
        if (rst || wb_do_branch)
            ifd_valid <= 1'b0;
        else
            ifd_valid <= ift_valid && cache_hit;
    end

    always_ff @(posedge clk) begin
        ifd_id_inf.pc <= 32'(ift_ifd_inf.fetched_pc);
        ifd_id_inf.pc_inc <= 32'(ift_ifd_inf.fetched_pc) + 32'h4; // PC+4
    end

    // Deliver instruction MUX'ed by cache block index to ID
    assign ifd_id_inf.instr = fetched_cache_line[pc_block_idx_reg*32 +: 32];
endmodule