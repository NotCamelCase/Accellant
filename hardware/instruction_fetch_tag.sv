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
    // IX -> IFT
    input logic             ix_stall_if,
    // IFD -> IFT
    input ifd_ift_inf_t     ifd_ift_inf,
    // IFT -> IFD
    output logic            ift_valid,
    output ift_ifd_inf_t    ift_ifd_inf
);
    // Start instructions from this address upon reset
    localparam  RESET_PC    = INSTR_ROM_BASE_ADDRESS;

    // PC reg
    logic[31:0]                 pc_reg;

    // Fetch status reg
    logic                       fetch_active_reg;

    ifu_address_t               last_pc_fetched;

    logic[ICACHE_NUM_WAYS-1:0]  valid_bits;

    always_ff @(posedge clk) begin
        if (rst)
            fetch_active_reg <= 1'b1;
        else if (ifd_ift_inf.cache_miss)
            fetch_active_reg <= 1'b0;
        else if (ifd_ift_inf.resume_fetch)
            fetch_active_reg <= 1'b1;
    end

    // PC
    always_ff @(posedge clk) begin
        if (rst)
            pc_reg <= RESET_PC;
        else if (fetch_active_reg) begin
            if (ifd_ift_inf.cache_miss)
                pc_reg <= pc_reg - 32'h4; // Cache miss, decrement PC and stall
            else if (wb_do_branch)
                pc_reg <= wb_branch_target;
            else if (!ix_stall_if)
                pc_reg <= pc_reg + 32'h4;
        end else if (wb_do_branch)
                pc_reg <= wb_branch_target;
    end

    assign last_pc_fetched = ifu_address_t'(pc_reg);

    // Way memories
    generate;
        for (genvar way_idx = 0; way_idx < ICACHE_NUM_WAYS; way_idx++) begin
            // CL valid lines
            logic   valid_bits_reg[ICACHE_NUM_SETS-1:0];

            always_ff @(posedge clk) begin
                if (rst || wb_icache_invalidate) begin
                    for (int set_idx = 0; set_idx < ICACHE_NUM_SETS; set_idx++)
                        valid_bits_reg[set_idx] <= 1'b0;
                end else if (ifd_ift_inf.update_tag_en[way_idx])
                    valid_bits_reg[ifd_ift_inf.update_tag_set] <= 1'b1; // Set valid bit on CL fetch
            end

            // CL tags
            bram_1r1w #(.ADDR_WIDTH(ICACHE_NUM_SET_BITS), .DATA_WIDTH(ICACHE_NUM_TAG_BITS)) tags(
                .clk(clk),
                .wr_en(ifd_ift_inf.update_tag_en[way_idx]),
                .rd_en(fetch_active_reg),
                .rd_addr(last_pc_fetched.set_idx),
                .wr_addr(ifd_ift_inf.update_tag_set),
                .wr_data(ifd_ift_inf.update_tag),
                .rd_data(ift_ifd_inf.tags_read[way_idx]));

            // Pass CL valid bit for way memory to IFD
            assign valid_bits[way_idx] = valid_bits_reg[last_pc_fetched.set_idx];
        end
    endgenerate

    always_ff @(posedge clk) begin
        if (rst || wb_do_branch)
            ift_valid <= 1'b0;
        else if (fetch_active_reg)
            ift_valid <= !(ifd_ift_inf.cache_miss || ix_stall_if);
    end

    always_ff @(posedge clk) begin
        ift_ifd_inf.fetched_pc <= pc_reg;
        ift_ifd_inf.valid_bits <= valid_bits;
    end
endmodule