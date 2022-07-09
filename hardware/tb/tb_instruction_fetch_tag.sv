`timescale 1ns/1ps

module tb_instruction_fetch_tag
(
);
    // Clock period
    localparam T = 10;

    // Inputs
    logic           clk; // 10 ns
    logic           rst; // Sync reset active-high
    logic           stall;
    logic           flush;
    logic           pc_src;
    logic[31:0]     branch_target;
    ifd_ift_inf_t   ifd_ift_inf;
    // Outputs
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
        stall <= 1'b0;
        flush <= 1'b0;
        pc_src <= 1'b0;

        ifd_ift_inf.cache_miss <= 1'b0;
        ifd_ift_inf.update_tag_en <= '0;
        @(negedge rst);

        // Have a cache miss for a single cycle and stall for a few
        ifd_ift_inf.cache_miss <= 1'b1;
        stall <= 1'b1;
        @(posedge clk);

        ifd_ift_inf.cache_miss <= 1'b0;
        repeat(5) @(posedge clk);

        // Cache miss handled, keep stalling until CL update arrives
        ifd_ift_inf.cache_miss <= 1'b0;
        @(posedge clk);

        // CL update for way 0, set 0 => tag=0x0
        ifd_ift_inf.update_tag_en <= 4'b0001;
        ifd_ift_inf.update_tag_set <= '0;
        ifd_ift_inf.update_tag <= '0;
        stall <= 1'b0;
        @(posedge clk);

        ifd_ift_inf.update_tag_en <= 4'b0;
        repeat(ICACHE_CL_SIZE / 4) @(posedge clk);

        // Cache miss
        ifd_ift_inf.cache_miss <= 1'b1;
        stall <= 1'b1;
        @(posedge clk);
        ifd_ift_inf.cache_miss <= 1'b0;

        repeat(5) @(posedge clk);

        // CL update for way 1, set 1 => tag=0x0
        ifd_ift_inf.update_tag_en <= 4'b0010;
        ifd_ift_inf.update_tag_set <= 6'b000001;
        ifd_ift_inf.update_tag <= '0;
        stall <= 1'b0;
        @(posedge clk);

        ifd_ift_inf.update_tag_en <= 4'b0;
        repeat(ICACHE_CL_SIZE / 4) @(posedge clk);

        @(posedge clk);

        $finish;
    end
endmodule