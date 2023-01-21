`timescale 1ns/1ps

module tb_instruction_fetch_data
(
);
    // Clock period
    localparam T = 10;

    // Inputs
    logic           clk; // 10 ns
    logic           rst; // Sync reset active-high
    logic           wb_do_branch;
    logic           wb_icache_invalidate;
    logic[31:0]     wb_branch_target;
    logic           ix_stall_if;
    logic           ift_valid;
    ift_ifd_inf_t   ift_ifd_inf;
    // Outputs
    logic           ifd_valid;
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

    instruction_fetch_tag ift(.*);

    instruction_fetch_data ifd(.*);

    initial begin
        wb_do_branch <= 1'b0;
        wb_icache_invalidate <= 1'b0;
        ix_stall_if <= 1'b0;
        @(negedge rst);

        repeat(50) @(posedge clk);

        wb_do_branch <= 1'b1;
        wb_branch_target <= 32'h0;
        @(posedge clk);
        wb_do_branch <= 1'b0;

        repeat(10) @(posedge clk);

        wb_do_branch <= 1'b1;
        wb_branch_target <= 32'h40;
        @(posedge clk);
        wb_do_branch <= 1'b0;

        wait(ifd_ift_inf.resume_fetch);

        repeat(21) @(posedge clk);

        wb_do_branch <= 1'b1;
        wb_branch_target <= 32'h0;
        @(posedge clk);
        wb_do_branch <= 1'b0;

        repeat(50) @(posedge clk);

        wb_do_branch <= 1'b1;
        wb_icache_invalidate <= 1'b1;
        wb_branch_target <= 32'h20;
        @(posedge clk);
        wb_do_branch <= 1'b0;
        wb_icache_invalidate <= 1'b0;

        wait(ifd_ift_inf.resume_fetch);

        repeat(25) @(posedge clk);

        $finish;
    end
endmodule