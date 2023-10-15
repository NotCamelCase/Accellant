`include "defines.svh"

import defines::*;

module load_store_data
(
    input logic                             clk, rst,
    // LST -> LSD
    input dcache_tag_t[DCACHE_NUM_WAYS-1:0] lst_writeback_tags,
    input logic                             lst_valid,
    input lst_lsd_inf_t                     lst_lsd_inf,
    // LSD -> Core
    output logic                            io_bus_rd_en,
    output logic                            io_bus_wr_en,
    output logic[NUM_IO_CORES-1:0]          io_bus_cs,
    output logic[31:0]                      io_bus_address,
    output logic[31:0]                      io_bus_wr_data,
    input logic[31:0]                       io_bus_rd_data,
    // LSD -> Core
    output logic[31:0]                      axi_dbus_awaddr,
    output logic[1:0]                       axi_dbus_awburst,
    output logic[7:0]                       axi_dbus_awlen,
    output logic[2:0]                       axi_dbus_awsize,
    output logic                            axi_dbus_awvalid,
    input logic                             axi_dbus_awready,
    output logic[31:0]                      axi_dbus_wdata,
    output logic[3:0]                       axi_dbus_wstrb,
    output logic                            axi_dbus_wlast,
    output logic                            axi_dbus_wvalid,
    input logic                             axi_dbus_wready,
    input logic[1:0]                        axi_dbus_bresp,
    input logic                             axi_dbus_bvalid,
    output logic                            axi_dbus_bready,
    output logic[31:0]                      axi_dbus_araddr,
    output logic[7:0]                       axi_dbus_arlen,
    output logic[2:0]                       axi_dbus_arsize,
    output logic[1:0]                       axi_dbus_arburst,
    output logic                            axi_dbus_arvalid,
    input logic                             axi_dbus_arready,
    input logic[31:0]                       axi_dbus_rdata,
    input logic[1:0]                        axi_dbus_rresp,
    input logic                             axi_dbus_rvalid,
    input logic                             axi_dbus_rlast,
    output logic                            axi_dbus_rready,
    // LSD -> LST
    output lsd_lst_inf_t                    lsd_lst_inf,
    // LSD -> IX
    output logic                            lsd_dcache_flush_done,
    // LSD -> WB
    output logic                            lsd_valid,
    output lsd_wb_inf_t                     lsd_wb_inf
);
    localparam  CL_DATA_WIDTH           = DCACHE_CL_SIZE * 8; // CL size in bits
    localparam  CL_NUM_WORDS            = CL_DATA_WIDTH / 32; // CL size in WORDs
    localparam  CL_SIZE_BITS            = $clog2(DCACHE_CL_SIZE);
    localparam  CL_FETCH_BITS           = $clog2(CL_NUM_WORDS);

    // Cache fetch state machine
    typedef enum {
        FETCH_IDLE,
        ISSUE_READ_ADDRESS,
        FETCH_DATA,
        REFILL_CL,
        FLUSH
    } fetch_state_t;

    // Writeback state machine
    typedef enum {
        WRITEBACK_IDLE,
        FETCH_CL_DATA_AND_TAG,
        COMPOSE_WRITEBACK_ADDRESS,
        ISSUE_WRITE_ADDRESS,
        EVICT_CL_DONE,
        WRITEBACK_CL
    } writeback_state_t;

    logic                               cache_hit, cache_miss;
    logic                               refill_cl, fetch_issue_address, evict_dirty_cl;
    logic                               writeback_idle, read_cl_flush, evict_dirty_cl_flush, flush_addr_within_range;

    logic[DCACHE_NUM_WAYS-1:0]          dirty_lines, dirty_lines_flush;
    logic[31:0]                         fetched_word;
    logic[31:0]                         composed_writeback_address;
    logic[CL_DATA_WIDTH-1:0]            fetched_cache_line;
    logic[CL_DATA_WIDTH-1:0]            writeback_cache_line;
    logic[CL_DATA_WIDTH-1:0]            pending_store_cache_line;

    logic[DCACHE_NUM_WAY_BITS-1:0]      hit_way_idx;
    logic[DCACHE_NUM_WAYS-1:0]          way_hit_bits;
    logic[DCACHE_NUM_WAYS-1:0]          replace_way_en;
    logic[DCACHE_NUM_BLOCK_BITS-1-2:0]  mem_block_idx_reg;

    logic[DCACHE_NUM_WAY_BITS-1:0]      way_replacement_reg;
    logic[DCACHE_NUM_WAY_BITS-1:0]      writeback_current_way_reg;
    logic[DCACHE_NUM_SET_BITS-1:0]      writeback_current_set_reg;

    // Cache fetch state machine
    fetch_state_t                       fetch_state_reg;
    logic                               update_tag_en_reg;
    logic[CL_FETCH_BITS-1:0]            fetch_ctr_reg;
    lsu_address_t                       fetch_address_reg;
    logic[CL_DATA_WIDTH-1:0]            fetched_words_reg;

    // Writeback state machine
    logic                               writeback_clear_cl_dirty_reg;
    logic                               writeback_dcache_flush_reg;
    logic                               writeback_pending_dcache_flush_reg;
    logic[31:0]                         writeback_wr_data_reg;
    logic[31:0]                         writeback_flush_addr_start_reg, writeback_flush_addr_end_reg;
    writeback_state_t                   writeback_state_reg;
    logic[CL_FETCH_BITS-1:0]            writeback_send_ctr_reg, writeback_send_ctr_nxt;
    lsu_address_t                       writeback_address_reg; // Memory address the evicted dirty CL should be written at

    // Pending store data to be registered before realizing a write hit
    logic                               pending_store_reg, mem_access_reg;
    logic[3:0]                          pending_store_wstrb_reg;
    logic[DCACHE_NUM_WAY_BITS-1:0]      pending_store_way_reg;
    logic[DCACHE_NUM_SET_BITS-1:0]      pending_store_set_idx_reg;
    logic[31:0]                         store_buffer;
    logic[31:0]                         store_word_masked;

    // Branch on D$ miss
    // Combinatorial signal to detect D$ miss after LST not to have 2-cycle branches, which complicates WB logic quite a bit
    assign lsd_wb_inf.do_branch = cache_miss;
    assign lsd_wb_inf.branch_target = lst_lsd_inf.pc;
    assign lsd_wb_inf.control_flow_pc = {lst_lsd_inf.pc[31:2], 2'b0}; // Branch info for BTP

    // AXI read interface
    assign axi_dbus_araddr = fetch_address_reg;
    assign axi_dbus_arburst = 2'b01; // INCR
    assign axi_dbus_arlen = CL_NUM_WORDS - 1; // AXI read burst length
    assign axi_dbus_arsize = 3'b010; // 32-bit read access
    assign axi_dbus_rready = 1'b1;

    // Register fetched data
    always_ff @(posedge clk) if (axi_dbus_rvalid) fetched_words_reg[fetch_ctr_reg*32 +: 32] <= axi_dbus_rdata;

    // Cache fetch
    always_ff @(posedge clk) begin
        if (rst) begin
            fetch_state_reg <= FETCH_IDLE;
            axi_dbus_arvalid <= 1'b0;
            update_tag_en_reg <= 1'b0;
        end else begin
            unique case (fetch_state_reg)
                FETCH_IDLE: begin
                    fetch_ctr_reg <= '0;

                    // If writeback of evicted CL is ongoing, stall until it's done
                    // so as to ensure coherency between data cache and main memory
                    if (cache_miss && (writeback_state_reg == WRITEBACK_IDLE)) begin
                        // Issue AXI read address
                        axi_dbus_arvalid <= 1'b1;

                        // Register read address
                        fetch_address_reg <= {lst_lsd_inf.mem_addr[31:CL_SIZE_BITS], {CL_SIZE_BITS{1'b0}}};

                        fetch_state_reg <= ISSUE_READ_ADDRESS;
                    end
                end

                ISSUE_READ_ADDRESS: begin
                    if (axi_dbus_arready) begin
                        // Read burst ready to commence
                        axi_dbus_arvalid <= 1'b0;
                        fetch_state_reg <= FETCH_DATA;
                    end
                end

                FETCH_DATA: begin
                    if (axi_dbus_rvalid) begin
                        // Read data has arrived
                        fetch_ctr_reg <= fetch_ctr_reg + CL_FETCH_BITS'(1);

                        // End of read burst
                        if (axi_dbus_rlast) begin
                            fetch_state_reg <= REFILL_CL;

                            // Prepare the CL to be evicted for writeback before re-fill
                            update_tag_en_reg <= 1'b1;
                        end
                    end
                end

                REFILL_CL: begin
                    update_tag_en_reg <= 1'b0;
                    fetch_state_reg <= FLUSH;
                end

                FLUSH: begin
                    fetch_state_reg <= FETCH_IDLE;
                end
            endcase
        end
    end

    // AXI write interface
    assign axi_dbus_awaddr = writeback_address_reg;
    assign axi_dbus_awburst = 2'b01; // INCR
    assign axi_dbus_wstrb = 4'b1111;
    assign axi_dbus_awlen = CL_NUM_WORDS - 1; // AXI write burst length
    assign axi_dbus_awsize = 3'b010; // 32-bit write access
    assign axi_dbus_wdata = writeback_wr_data_reg;
    assign axi_dbus_bready = 1'b1;

    assign writeback_send_ctr_nxt = writeback_send_ctr_reg + CL_FETCH_BITS'(1);

    assign composed_writeback_address = {lst_writeback_tags[writeback_current_way_reg], writeback_current_set_reg, {CL_SIZE_BITS{1'b0}}};

    assign flush_addr_within_range =
        (composed_writeback_address >= writeback_flush_addr_start_reg) &&
        (composed_writeback_address < writeback_flush_addr_end_reg);

    always_ff @(posedge clk) begin
        if (axi_dbus_wvalid && axi_dbus_wready) // Burst ongoing, register next data to be written back
            writeback_wr_data_reg <= writeback_cache_line[writeback_send_ctr_nxt*32 +: 32];
        else // Burst stalled, retain data at current counter
            writeback_wr_data_reg <= writeback_cache_line[writeback_send_ctr_reg*32 +: 32];
    end

    // If D$ flush request arrives while writeback of an evicted CL is ongoing,
    // store this information to handle D$ flush post-eviction
    always_ff @(posedge clk) begin
        if (rst)
            writeback_pending_dcache_flush_reg <= 1'b0;
        else if (!writeback_idle && (lst_valid && lst_lsd_inf.dcache_flush))
            writeback_pending_dcache_flush_reg <= 1'b1;
        else if (lsd_dcache_flush_done)
            writeback_pending_dcache_flush_reg <= 1'b0;
    end

    // Cache writeback
    always_ff @(posedge clk) begin
        if (rst) begin
            writeback_state_reg <= WRITEBACK_IDLE;
            writeback_clear_cl_dirty_reg <= 1'b0;
            axi_dbus_awvalid <= 1'b0;
            axi_dbus_wvalid <= 1'b0;
            axi_dbus_wlast <= 1'b0;
            writeback_flush_addr_start_reg <= '0;
            writeback_flush_addr_end_reg <= 32'hffffffff;
        end else begin
            unique case (writeback_state_reg)
                WRITEBACK_IDLE: begin
                    writeback_clear_cl_dirty_reg <= 1'b0;

                    // Register CL writeback address before issueing AXI write address
                    // For single-CL writeback, tags are read during refill, before new tag is inserted
                    writeback_address_reg <= {lst_writeback_tags[way_replacement_reg], fetch_address_reg.set_idx, {CL_SIZE_BITS{1'b0}}};

                    writeback_dcache_flush_reg <= 1'b0;
                    lsd_dcache_flush_done <= 1'b0;

                    writeback_current_way_reg <= '0;
                    writeback_current_set_reg <= '0;

                    writeback_flush_addr_start_reg <= lst_lsd_inf.dcache_flush_start_addr;
                    writeback_flush_addr_end_reg <= lst_lsd_inf.dcache_flush_end_addr;

                    if (evict_dirty_cl) begin
                        writeback_current_way_reg <= way_replacement_reg;
                        axi_dbus_awvalid <= 1'b1;
                        writeback_state_reg <= ISSUE_WRITE_ADDRESS; // CL data and adress are ready to go, assert awvalid directly and transition into ISSUE_WRITE_ADDRESS
                    end

                    if ((lst_valid && lst_lsd_inf.dcache_flush) || writeback_pending_dcache_flush_reg) begin
                        writeback_dcache_flush_reg <= 1'b1;
                        writeback_state_reg <= FETCH_CL_DATA_AND_TAG;
                    end
                end

                FETCH_CL_DATA_AND_TAG: begin
                    // Read CL data and tag in parallel ahead of address issuence to writeback dirty CL
                    if (evict_dirty_cl_flush)
                        writeback_state_reg <= COMPOSE_WRITEBACK_ADDRESS;
                    else
                        writeback_state_reg <= EVICT_CL_DONE;
                end

                COMPOSE_WRITEBACK_ADDRESS: begin
                    // Don't flush the CL to main memory if the address of the next dirty CL to be flushed is not within the flush range
                    if (flush_addr_within_range) begin
                        writeback_state_reg <= ISSUE_WRITE_ADDRESS;
                        axi_dbus_awvalid <= 1'b1;
                    end else begin
                        writeback_state_reg <= EVICT_CL_DONE;
                    end

                    // Refresh writeback address to flush current dirty CL on a given way part of the set
                    writeback_address_reg <= composed_writeback_address;
                end

                ISSUE_WRITE_ADDRESS: begin
                    writeback_send_ctr_reg <= '0;

                    if (axi_dbus_awready) begin
                        axi_dbus_awvalid <= 1'b0;
                        axi_dbus_wvalid <= 1'b1;
                        writeback_state_reg <= WRITEBACK_CL;
                    end
                end

                WRITEBACK_CL: begin
                    if (axi_dbus_wready) begin
                        if (writeback_send_ctr_reg == CL_FETCH_BITS'(CL_NUM_WORDS-1)) begin
                            // End of write burst
                            axi_dbus_wvalid <= 1'b0;
                            axi_dbus_wlast <= 1'b0;
                            writeback_clear_cl_dirty_reg <= 1'b1; // CL has been written back to main memory, clear its dirty bit

                            if (writeback_dcache_flush_reg)
                                writeback_state_reg <= EVICT_CL_DONE;
                            else
                                writeback_state_reg <= WRITEBACK_IDLE;
                        end else begin
                            writeback_send_ctr_reg <= writeback_send_ctr_nxt;

                            if (writeback_send_ctr_reg == CL_FETCH_BITS'(CL_NUM_WORDS-2))
                                axi_dbus_wlast <= 1'b1;
                        end
                    end
                end

                EVICT_CL_DONE: begin
                    writeback_clear_cl_dirty_reg <= 1'b0;

                    if (writeback_current_way_reg == DCACHE_NUM_WAY_BITS'(DCACHE_NUM_WAYS-1)) begin
                        if (writeback_current_set_reg == DCACHE_NUM_SET_BITS'(DCACHE_NUM_SETS-1)) begin
                            lsd_dcache_flush_done <= 1'b1; // End of D$ flush
                            writeback_state_reg <= WRITEBACK_IDLE;
                        end else begin
                            writeback_current_set_reg <= writeback_current_set_reg + DCACHE_NUM_SET_BITS'(1);
                            writeback_current_way_reg <= '0;
                            writeback_state_reg <= FETCH_CL_DATA_AND_TAG; // Continue onto the next set
                        end
                    end else begin
                        writeback_current_way_reg <= writeback_current_way_reg + DCACHE_NUM_WAY_BITS'(1);
                        writeback_state_reg <= FETCH_CL_DATA_AND_TAG; // Continue onto the next way
                    end
                end
            endcase
        end
    end

    // Simple round-robin counter to select which way to replace
    // If re-working, remember to update writeback address logic accordingly!
    always_ff @(posedge clk) begin
        if (rst)
            way_replacement_reg <= '0;
        else if (update_tag_en_reg)
            way_replacement_reg <= way_replacement_reg + DCACHE_NUM_WAY_BITS'(1);
    end

    // Convert selected way from binary to index
    always_comb begin
        replace_way_en = {DCACHE_NUM_WAYS{1'b0}};
        replace_way_en[way_replacement_reg] = 1'b1;
    end

    assign refill_cl = (fetch_state_reg == REFILL_CL);
    assign writeback_idle = (writeback_state_reg == WRITEBACK_IDLE);
    assign fetch_issue_address = (fetch_state_reg == ISSUE_READ_ADDRESS);
    assign read_cl_flush = (writeback_state_reg == FETCH_CL_DATA_AND_TAG);
    assign evict_dirty_cl = refill_cl && dirty_lines[way_replacement_reg];
    assign evict_dirty_cl_flush = dirty_lines_flush[writeback_current_way_reg];

    assign lsd_lst_inf.update_tag_en = replace_way_en & {DCACHE_NUM_WAYS{update_tag_en_reg}};
    assign lsd_lst_inf.update_tag_set = fetch_address_reg.set_idx;
    assign lsd_lst_inf.evict_set = read_cl_flush ? writeback_current_set_reg : fetch_address_reg.set_idx;
    assign lsd_lst_inf.update_tag = fetch_address_reg.tag_idx;

    // CL data
    bram_2r1w #(.ADDR_WIDTH(DCACHE_NUM_SET_BITS + DCACHE_NUM_WAY_BITS), .DATA_WIDTH(CL_DATA_WIDTH), .READ_BYPASS(1)) cache_lines(
        .clk(clk),
        .wr_en(update_tag_en_reg || pending_store_reg),
        .rd_en_a(cache_hit),
        .rd_en_b(fetch_issue_address || read_cl_flush), // Either fetch CL data before a refill for single-CL writeback or for each set to flush to dirty CLs
        .rd_addr_a({hit_way_idx, lst_lsd_inf.mem_addr.set_idx}),
        .rd_addr_b(read_cl_flush ? {writeback_current_way_reg, writeback_current_set_reg} : {way_replacement_reg, fetch_address_reg.set_idx}),
        .wr_addr(update_tag_en_reg ? {way_replacement_reg, fetch_address_reg.set_idx} : {pending_store_way_reg, pending_store_set_idx_reg}),
        .wr_data(update_tag_en_reg ? fetched_words_reg : pending_store_cache_line), // Store data comes either from a CL refill or pending store buffer
        .rd_data_a(fetched_cache_line),
        .rd_data_b(writeback_cache_line));

    // CL dirty bits
    generate
        for (genvar way_idx = 0; way_idx < DCACHE_NUM_WAYS; way_idx++) begin
            logic   dirty_lines_reg[DCACHE_NUM_SETS-1:0];

            logic   clear_current_cl;

            always_ff @(posedge clk) begin
                if (rst) begin
                    for (int set_idx = 0; set_idx < DCACHE_NUM_SETS; set_idx++)
                        dirty_lines_reg[set_idx] <= 1'b0;
                end else if (pending_store_reg && (way_idx == pending_store_way_reg))
                    dirty_lines_reg[pending_store_set_idx_reg] <= 1'b1; // Mark the CL dirty after a store
                else if (writeback_clear_cl_dirty_reg && (way_idx == writeback_current_way_reg) && clear_current_cl)
                    dirty_lines_reg[writeback_address_reg.set_idx] <= 1'b0; // Reset dirty bit when a CL has been evicted and replaced w/ a new CL
            end

            // Read CL dirty status
            assign dirty_lines[way_idx] = dirty_lines_reg[fetch_address_reg.set_idx];
            assign dirty_lines_flush[way_idx] = dirty_lines_reg[writeback_current_set_reg];

            // Clear CL dirty bit only if the refill was not previously a store
            assign clear_current_cl = !dirty_lines_reg[writeback_address_reg.set_idx];
        end
    endgenerate

    // Compare CL tags read in LST and determine cache hit/miss based on valid bit
    generate
        for (genvar way_idx = 0; way_idx < DCACHE_NUM_WAYS; way_idx++)
            assign way_hit_bits[way_idx] = lst_lsd_inf.valid_bits[way_idx] && (lst_lsd_inf.tags_read[way_idx] == lst_lsd_inf.mem_addr.tag_idx);
    endgenerate

    // Convert hit way index to binary
    always_comb begin
        hit_way_idx = '0;

        for (int index = 0; index < DCACHE_NUM_WAYS; index++) begin
            if (way_hit_bits[index])
                hit_way_idx |= index[DCACHE_NUM_WAY_BITS-1:0];
        end
    end

    // Cache hit occurs if there was a tag match on a valid CL
    assign cache_hit = |way_hit_bits;

    // Cache miss occurs when no valid CL had its tag matched during a cycle input was valid
    assign cache_miss = lst_valid && lst_lsd_inf.cacheable_mem_access && !cache_hit;

    // Pending store data which is written one cycle after a write hit
    always_ff @(posedge clk) begin
        if (lst_valid && lst_lsd_inf.cacheable_mem_access)
            pending_store_reg <= cache_hit && lst_lsd_inf.mem_store;
        else
            pending_store_reg <= 1'b0;

        // If cache miss, refresh pending store way during tag update
        if (cache_hit)
            pending_store_way_reg <= hit_way_idx;
        else if (update_tag_en_reg)
            pending_store_way_reg <= way_replacement_reg;

        pending_store_set_idx_reg <= lst_lsd_inf.mem_addr.set_idx;
        pending_store_wstrb_reg <= lst_lsd_inf.write_strobe;

        store_buffer[7:0]   <= ({8{lst_lsd_inf.write_strobe[0]}} & lst_lsd_inf.write_data[7:0]);
        store_buffer[15:8]  <= ({8{lst_lsd_inf.write_strobe[1]}} & lst_lsd_inf.write_data[15:8]);
        store_buffer[23:16] <= ({8{lst_lsd_inf.write_strobe[2]}} & lst_lsd_inf.write_data[23:16]);
        store_buffer[31:24] <= ({8{lst_lsd_inf.write_strobe[3]}} & lst_lsd_inf.write_data[31:24]);
    end

    always_ff @(posedge clk) mem_block_idx_reg <= lst_lsd_inf.mem_addr.block_idx[DCACHE_NUM_BLOCK_BITS-1:2]; // Byte-offset ignored

    // Current word in memory at given location -- this always comes from D$ because D$-missed CLs are always first written onto D$ after getting fetched
    assign fetched_word = fetched_cache_line[mem_block_idx_reg*32 +: 32];

    // Word to be modified w/ write-strobe per byte lane and fetched word
    assign store_word_masked[7:0]   = store_buffer[7:0]   | ({8{~pending_store_wstrb_reg[0]}} & fetched_word[7:0]);
    assign store_word_masked[15:8]  = store_buffer[15:8]  | ({8{~pending_store_wstrb_reg[1]}} & fetched_word[15:8]);
    assign store_word_masked[23:16] = store_buffer[23:16] | ({8{~pending_store_wstrb_reg[2]}} & fetched_word[23:16]);
    assign store_word_masked[31:24] = store_buffer[31:24] | ({8{~pending_store_wstrb_reg[3]}} & fetched_word[31:24]);

    // Update CL w/ buffered store data
    always_comb begin
        pending_store_cache_line = fetched_cache_line;
        pending_store_cache_line[mem_block_idx_reg*32 +: 32] = store_word_masked;
    end

    always_ff @(posedge clk) begin
        if (rst)
            lsd_valid <= 1'b0;
        else
            lsd_valid <= (lst_valid && (lst_lsd_inf.dcache_flush || (cache_hit && lst_lsd_inf.cacheable_mem_access))) || ((|lst_lsd_inf.io_cs) && (lst_lsd_inf.io_rd_en || lst_lsd_inf.io_wr_en));
    end

    // Outputs to WB
    always_ff @(posedge clk) begin
        lsd_wb_inf.register_write <= lst_lsd_inf.register_write;
        lsd_wb_inf.unaligned_mem_access <= lst_lsd_inf.unaligned_mem_access;
        lsd_wb_inf.rd <= lst_lsd_inf.rd;
        lsd_wb_inf.load_selector <= lst_lsd_inf.mem_addr[1:0];
        lsd_wb_inf.load_control <= lst_lsd_inf.mem_load_op;
    end

    // Register if the last access was a memory access or a non-cacheable I/O access
    always_ff @(posedge clk) mem_access_reg <= lst_lsd_inf.cacheable_mem_access;

    // IO data
    assign io_bus_rd_en = lst_lsd_inf.io_rd_en;
    assign io_bus_wr_en = lst_lsd_inf.io_wr_en;
    assign io_bus_cs = lst_lsd_inf.io_cs;
    assign io_bus_address = lst_lsd_inf.mem_addr;
    assign io_bus_wr_data = lst_lsd_inf.write_data;

    // Route read data from CL or I/O interconnect to WB
    assign lsd_wb_inf.load_result = mem_access_reg ? fetched_word : io_bus_rd_data;
endmodule