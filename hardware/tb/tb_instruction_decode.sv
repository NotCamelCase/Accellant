`timescale 1ns/1ps

module tb_instruction_decode
(
);
    // Clock period
    localparam T = 10;

    // Inputs
    logic               clk; // 10 ns
    logic               rst; // Sync reset active-high
    logic               wb_do_branch;
    logic               wb_icache_invalidate;
    logic[31:0]         wb_branch_target;
    logic               ift_valid;
    ift_ifd_inf_t       ift_ifd_inf;
    logic               ifd_valid;
    ifd_id_inf_t        ifd_id_inf;
    ifd_ift_inf_t       ifd_ift_inf;
    // Outputs
    logic               id_valid;
    id_ix_inf_t         id_ix_inf;

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

    instruction_decode id(.*);

    initial begin
        wb_do_branch <= 1'b0;
        wb_icache_invalidate <= 1'b0;
        @(negedge rst);

        repeat(50) @(posedge clk);

        $finish;
    end
endmodule