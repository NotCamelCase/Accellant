`timescale 1ns/1ps

module tb_instruction_fetch_data
(
);
    // Clock period
    localparam T = 10;

    // Inputs
    logic           clk; // 10 ns
    logic           rst; // Sync reset active-high
    logic           stall;
    logic           flush;
    ift_ifd_inf_t   ift_ifd_inf;
    // Outputs
    logic           icache_busy;
    ifd_ift_inf_t   ifd_ift_inf;
    ifd_id_inf_t    ifd_id_inf;

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

    instruction_fetch_data ifd(.*);

    initial begin
        ift_ifd_inf.ctrl.instruction_valid <= 1'b0;

        stall <= 1'b0;
        flush <= 1'b0;
        @(negedge rst);

        ift_ifd_inf.fetched_pc <= 32'h0;
        ift_ifd_inf.valid_bits = '0;
        ift_ifd_inf.tags_read <= '0;
        ift_ifd_inf.ctrl.instruction_valid <= 1'b1;
        @(posedge clk);

        // Cache miss occurred, stall
        stall <= 1'b1;
        ift_ifd_inf.ctrl.instruction_valid <= 1'b0;
        wait(|ifd_ift_inf.update_tag_en);

        ift_ifd_inf.tags_read <= {ICACHE_NUM_WAYS{ifd_ift_inf.update_tag}};
        ift_ifd_inf.valid_bits = ifd_ift_inf.update_tag_en;
        wait(icache_busy);
        stall <= 1'b0;
        ift_ifd_inf.ctrl.instruction_valid <= 1'b1;
        @(posedge clk);

        ift_ifd_inf.fetched_pc <= ift_ifd_inf.fetched_pc + 32'h4;
        @(posedge clk);

        ift_ifd_inf.fetched_pc <= ift_ifd_inf.fetched_pc + 32'h4;
        @(posedge clk);

        ift_ifd_inf.fetched_pc <= ift_ifd_inf.fetched_pc + 32'h4;
        @(posedge clk);

        ift_ifd_inf.fetched_pc <= ift_ifd_inf.fetched_pc + 32'h4;
        @(posedge clk);

        ift_ifd_inf.fetched_pc <= ift_ifd_inf.fetched_pc + 32'h4;
        @(posedge clk);

        ift_ifd_inf.fetched_pc <= ift_ifd_inf.fetched_pc + 32'h4;
        @(posedge clk);

        ift_ifd_inf.fetched_pc <= ift_ifd_inf.fetched_pc + 32'h4;
        @(posedge clk);

        ift_ifd_inf.fetched_pc <= ift_ifd_inf.fetched_pc + 32'h4;
        @(posedge clk);

        ift_ifd_inf.fetched_pc <= ift_ifd_inf.fetched_pc + 32'h4;
        @(posedge clk);

        ift_ifd_inf.fetched_pc <= ift_ifd_inf.fetched_pc + 32'h4;
        @(posedge clk);

        ift_ifd_inf.fetched_pc <= ift_ifd_inf.fetched_pc + 32'h4;
        @(posedge clk);

        ift_ifd_inf.fetched_pc <= ift_ifd_inf.fetched_pc + 32'h4;
        @(posedge clk);

        ift_ifd_inf.fetched_pc <= ift_ifd_inf.fetched_pc + 32'h4;
        @(posedge clk);

        ift_ifd_inf.fetched_pc <= ift_ifd_inf.fetched_pc + 32'h4;
        @(posedge clk);

        ift_ifd_inf.fetched_pc <= ift_ifd_inf.fetched_pc + 32'h4;
        @(posedge clk);

        ift_ifd_inf.fetched_pc <= ift_ifd_inf.fetched_pc + 32'h4;
        // New set, cache miss must occur
        ift_ifd_inf.valid_bits = '0;
        @(posedge clk);

        @(posedge clk);
        @(posedge clk);

        $finish;
    end
endmodule