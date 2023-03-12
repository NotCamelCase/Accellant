`include "defines.svh"
`include "memory_map.svh"

import defines::*;

module instruction_fetch_tag
(
    input logic             clk, rst,
    // WB -> IFT
    input logic             wb_do_branch,
    input logic             wb_icache_invalidate,
    input logic[31:0]       wb_branch_target,
    input logic[31:0]       wb_control_flow_pc,
    // IX -> IFT
    input logic             ix_stall_if,
    // IFD -> IFT
    input ifd_ift_inf_t     ifd_ift_inf,
    // IFT -> IFD
    output logic            ift_valid,
    output ift_ifd_inf_t    ift_ifd_inf,
    // IFT -> ID
    output btp_info_t       ift_id_btp_info
);
`ifdef XILINX_SIMULATOR
    localparam  RESET_PC    = 0; // Bypass bootloader and issue instructions directly from RAM assuming it's burn into the model
`else
    localparam  RESET_PC    = INSTR_ROM_BASE_ADDRESS; // Start executing instructions from Boot ROM to blit program binary onto RAM
`endif

    // Number of entries in BTP
    localparam  NUM_BTP_ENTRIES = 1024;
    localparam  BTP_ENTRIES_BIT = $clog2(NUM_BTP_ENTRIES);

    // BTP entry
    typedef struct packed {
        logic[32-BTP_ENTRIES_BIT-2-1:0] tag;        // Control-flow instruction PC (ignore 2 LSBs)
        logic[29:0]                     target_pc;  // Branch target
    } btp_entry_t;

    // PC reg
    logic[31:0]                 pc_reg, pc_prev_reg;
    ifu_address_t               last_pc_fetched;

    // Fetch status reg
    logic                       fetch_active_reg;

    logic[ICACHE_NUM_WAYS-1:0]  cl_valid_bits;

    // BTP
    logic                       btp_taken;
    logic                       btp_use_reg;
    logic                       btp_valid_reg[NUM_BTP_ENTRIES-1:0];
    btp_entry_t                 current_btp_entry, new_btp_entry;

    // BTB
    bram_1r1w #(.ADDR_WIDTH(BTP_ENTRIES_BIT), .DATA_WIDTH($bits(btp_entry_t))) btb(
        .clk(clk),
        .wr_en(wb_do_branch),
        .rd_en(1'b1),
        .rd_addr(last_pc_fetched[BTP_ENTRIES_BIT+1:2]),
        .wr_addr(wb_control_flow_pc[BTP_ENTRIES_BIT+1:2]),
        .wr_data(new_btp_entry),
        .rd_data(current_btp_entry));

    always_ff @(posedge clk) begin
        if (rst)
            fetch_active_reg <= 1'b1;
        else if (ifd_ift_inf.cache_miss)
            fetch_active_reg <= 1'b0;
        else if (ifd_ift_inf.resume_fetch || wb_do_branch)
            fetch_active_reg <= 1'b1;
    end

    // PC
    always_ff @(posedge clk) begin
        if (rst) begin
            pc_prev_reg <= RESET_PC;
            pc_reg <= RESET_PC; // Start instructions from this address upon reset
        end else if (wb_do_branch) begin
            pc_prev_reg <= last_pc_fetched;
            pc_reg <= last_pc_fetched + 32'h4;
        end else if (fetch_active_reg) begin
            if (ifd_ift_inf.cache_miss) begin
                pc_prev_reg <= pc_prev_reg - 32'h4;
                pc_reg <= pc_prev_reg; // Cache miss, decrement PC and stall
            end else if (!ix_stall_if) begin
                pc_prev_reg <= last_pc_fetched;
                pc_reg <= last_pc_fetched + 32'h4;
            end
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            for (int idx = 0; idx < NUM_BTP_ENTRIES; idx++)
                btp_valid_reg[idx] <= 1'b0;
        end else if (wb_do_branch)
            btp_valid_reg[wb_control_flow_pc[BTP_ENTRIES_BIT+1:2]] <= wb_control_flow_pc[0];
    end

    always_ff @(posedge clk) begin
        if (rst)
            btp_use_reg <= 1'b0;
        else
            btp_use_reg <= btp_valid_reg[last_pc_fetched[BTP_ENTRIES_BIT+1:2]]; // Registered w/ last fetched PC to ease timing
    end

    // New BTP entry to be inserted when a branch has taken place
    assign new_btp_entry.tag = wb_control_flow_pc[31:BTP_ENTRIES_BIT+2];
    assign new_btp_entry.target_pc = wb_branch_target[31:2];

    // If the last fetched PC has a valid BTP entry, predict next PC to be taken
    // such that we fetch from the target PC instead of PC+4 next clock cycle.
    // Because IFD only allows at most one outstanding cache miss, stop steering by BTP
    // not to cause further I$ misses before fetching the last I$-missed instruction.
    assign btp_taken = ifd_ift_inf.cache_fetch_fsm_idle && btp_use_reg && (current_btp_entry.tag == pc_prev_reg[31:BTP_ENTRIES_BIT+2]);

    assign last_pc_fetched = ifu_address_t'({(
                        wb_do_branch ? wb_branch_target[31:2] :
                        (ix_stall_if ? pc_prev_reg[31:2] :
                        (btp_taken ? current_btp_entry.target_pc :
                        pc_reg[31:2]))), 2'b0});

    // Way memories
    generate;
        for (genvar way_idx = 0; way_idx < ICACHE_NUM_WAYS; way_idx++) begin
            // CL valid lines
            logic   valid_bits_reg[ICACHE_NUM_SETS-1:0];

            always_ff @(posedge clk) begin
                if (rst || (wb_do_branch && wb_icache_invalidate)) begin
                    for (int set_idx = 0; set_idx < ICACHE_NUM_SETS; set_idx++)
                        valid_bits_reg[set_idx] <= 1'b0;
                end else if (ifd_ift_inf.update_tag_en[way_idx])
                    valid_bits_reg[ifd_ift_inf.update_tag_set] <= 1'b1; // Set valid bit on CL fetch
            end

            // CL tags
            bram_1r1w #(.ADDR_WIDTH(ICACHE_NUM_SET_BITS), .DATA_WIDTH(ICACHE_NUM_TAG_BITS)) tags(
                .clk(clk),
                .wr_en(ifd_ift_inf.update_tag_en[way_idx]),
                .rd_en(fetch_active_reg || wb_do_branch),
                .rd_addr(last_pc_fetched.set_idx),
                .wr_addr(ifd_ift_inf.update_tag_set),
                .wr_data(ifd_ift_inf.update_tag),
                .rd_data(ift_ifd_inf.tags_read[way_idx]));

            // Pass CL valid bit for way memory to IFD
            assign cl_valid_bits[way_idx] = !(wb_do_branch && wb_icache_invalidate) && valid_bits_reg[last_pc_fetched.set_idx];
        end
    endgenerate

    // BTP info to ID
    // This is effectively the BTP info of the last fetched instruction
    // that's being decoded at ID because BTB has 1 clk cycle latency
    always_ff @(posedge clk) begin
        ift_id_btp_info.branch_taken <= btp_taken;
        ift_id_btp_info.branch_target <= {current_btp_entry.target_pc, 2'b0};
    end

    // Outputs to IFD
    always_ff @(posedge clk) begin
        if (rst)
            ift_valid <= 1'b0;
        else if (wb_do_branch)
            ift_valid <= 1'b1;
        else if (fetch_active_reg)
            ift_valid <= !(ifd_ift_inf.cache_miss || ix_stall_if);
    end

    always_ff @(posedge clk) begin
        ift_ifd_inf.fetched_pc <= last_pc_fetched;
        ift_ifd_inf.valid_bits <= cl_valid_bits;
    end
endmodule