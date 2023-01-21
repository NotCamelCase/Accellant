`timescale 1ns/1ps

module tb_instruction_fetch_tag
(
);
    // Clock period
    localparam T = 10;

    localparam  RESET_PC = 32'h0;

    // Inputs
    logic           clk; // 10 ns
    logic           rst; // Sync reset active-high
    logic           wb_do_branch;
    logic           wb_icache_invalidate;
    logic[31:0]     wb_branch_target;
    ifd_ift_inf_t   ifd_ift_inf;
    // Outputs
    logic           ift_valid;
    ift_ifd_inf_t   ift_ifd_inf;

    always begin
        clk = 1'b1;
        #(T/2);
        clk = 1'b0;
        #(T/2);
    end

    initial begin
        rst = 1'b1;
        #(2*T);
        rst = 1'b0;
    end

    instruction_fetch_tag ift(.*);

    initial begin
        wb_do_branch <= 1'b0;
        wb_icache_invalidate <= 1'b0;
        ifd_ift_inf.update_tag_en <= 1'b0;
        ifd_ift_inf.resume_fetch <= 1'b0;
        ifd_ift_inf.cache_miss <= 1'b0;
        @(negedge rst);

        // Cache miss
        ifd_ift_inf.cache_miss <= 1'b1;
        @(posedge clk);
        ifd_ift_inf.cache_miss <= 1'b0;
        repeat(5) @(posedge clk);

        // Cache refilled
        ifd_ift_inf.update_tag_en <= 4'b0001;
        ifd_ift_inf.update_tag_set <= 6'b0;
        ifd_ift_inf.update_tag <= '0;
        @(posedge clk);

        // Flush cycle
        ifd_ift_inf.update_tag_en <= '0;
        ifd_ift_inf.resume_fetch <= 1'b1;
        @(posedge clk);

        ifd_ift_inf.resume_fetch <= 1'b0;
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);

        wait(ift_ifd_inf.valid_bits == '0);

        ifd_ift_inf.cache_miss <= 1'b1;
        @(posedge clk);
        ifd_ift_inf.cache_miss <= 1'b0;
        repeat(5) @(posedge clk);

        // Cache refill
        ifd_ift_inf.update_tag_en <= 4'b1000;
        ifd_ift_inf.update_tag_set <= 6'b1;
        ifd_ift_inf.update_tag <= '0;
        @(posedge clk);

        // Flush cycle
        ifd_ift_inf.update_tag_en <= '0;
        ifd_ift_inf.resume_fetch <= 1'b1;
        @(posedge clk);

        ifd_ift_inf.resume_fetch <= 1'b0;
        @(posedge clk);

        repeat(5) @(posedge clk);

        wb_do_branch <= 1'b1;
        wb_branch_target <= 32'd12;
        @(posedge clk);
        // Invalid input cycle due to branching just taken place
        wb_do_branch <= 1'b0;
        @(posedge clk);

        repeat(5) @(posedge clk);

        wb_do_branch <= 1'b1;
        wb_icache_invalidate <= 1'b1;
        wb_branch_target <= 32'd0;
        @(posedge clk);
        // Invalid input cycle due to I$ invalidation just taken place
        wb_do_branch <= 1'b0;
        wb_icache_invalidate <= 1'b0;
        @(posedge clk);

        // IFD not ready due to cache miss
        ifd_ift_inf.cache_miss <= 1'b1;
        @(posedge clk);
        ifd_ift_inf.cache_miss <= 1'b0;
        repeat(5) @(posedge clk);

        // Cache refilled
        ifd_ift_inf.update_tag_en <= 4'b0001;
        ifd_ift_inf.update_tag_set <= 6'b0;
        ifd_ift_inf.update_tag <= '0;
        @(posedge clk);

        // Flush cycle
        ifd_ift_inf.update_tag_en <= '0;
        ifd_ift_inf.resume_fetch <= 1'b1;
        @(posedge clk);
        ifd_ift_inf.resume_fetch <= 1'b0;
        @(posedge clk);

        wait(ift_ifd_inf.valid_bits == '0);

        $finish;
    end
endmodule