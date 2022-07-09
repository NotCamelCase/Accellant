`include "defines.svh"

module instruction_fetch_tag
(
    input logic             clk, rst,
    // From Core
    input logic             stall,
    input logic             flush,
    input logic             pc_src,
    input logic[31:0]       branch_target,
    // From instruction_fetch_data
    input ifd_ift_inf_t     ifd_ift_inf,
    // To instruction_fetch_data
    output ift_ifd_inf_t    ift_ifd_inf
);
    // Start instructions from this address upon reset
    localparam  RESET_PC        = 32'h0;

    // PC reg
    logic[31:0]                 last_pc_reg;

    instr_pc_t                  last_pc_fetched;
    logic[ICACHE_NUM_WAYS-1:0]  valid_bits;

    //TODO: Incorporate stall/flush logic from Core properly!
    always_ff @(posedge clk) begin
        if (rst)
            last_pc_reg <= RESET_PC;
        else if (ifd_ift_inf.cache_miss) // Priority over stall
            last_pc_reg <= last_pc_reg - 32'h4; // Decrement PC to re-try after IFD fetches CL
        else if (!stall)
            last_pc_reg <= pc_src ? {branch_target[31:1], 1'b0} : last_pc_reg + 32'h4; // Jump to branch target or increment PC
    end

    assign last_pc_fetched = instr_pc_t'(last_pc_reg);

    // Way memories
    generate;
        for (genvar way_idx = 0; way_idx < ICACHE_NUM_WAYS; way_idx++) begin
            // CL valid lines
            logic   valid_bits_reg[ICACHE_NUM_SETS-1:0];

            always_ff @(posedge clk) begin
                if (rst) begin //TODO: Implement fence.i to invalidate icache!
                    for (int set_idx = 0; set_idx < ICACHE_NUM_SETS; set_idx++)
                        valid_bits_reg[set_idx] <= `FALSE;
                end else if (ifd_ift_inf.update_tag_en[way_idx])
                        valid_bits_reg[ifd_ift_inf.update_tag_set] <= `TRUE; // Set valid bit on CL fetch
            end

            // CL tags
            bram_1r1w #(.ADDR_WIDTH(ICACHE_NUM_SET_BITS), .DATA_WIDTH(ICACHE_NUM_TAG_BITS)) tags(
                .clk(clk),
                .wr_en(ifd_ift_inf.update_tag_en[way_idx]),
                .rd_addr(last_pc_fetched.set_idx),
                .wr_addr(ifd_ift_inf.update_tag_set),
                .wr_data(ifd_ift_inf.update_tag),
                .rd_data(ift_ifd_inf.tags_read[way_idx]));

            // Pass CL valid bit for way memory to IFD
            assign valid_bits[way_idx] = (ifd_ift_inf.update_tag_en[way_idx] && (ifd_ift_inf.update_tag_set == last_pc_fetched.set_idx)) ? `TRUE :
                                         valid_bits_reg[last_pc_fetched.set_idx];
        end
    endgenerate

    // Control signals to IFD
    always_ff @(posedge clk) begin
        if (rst || flush) //TODO: Combine rst /w flush
            ift_ifd_inf.ctrl.instruction_valid <= `FALSE;
        else
            ift_ifd_inf.ctrl.instruction_valid <= ~stall;
    end

    always_ff @(posedge clk) begin
        ift_ifd_inf.fetched_pc <= last_pc_fetched;
        ift_ifd_inf.valid_bits <= valid_bits;
    end
endmodule