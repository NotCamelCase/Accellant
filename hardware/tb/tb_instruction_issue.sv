`timescale 1ns/1ps

module tb_instruction_issue
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
    logic               ix_stall_if;
    logic               ift_valid, ifd_valid, id_valid;
    ift_ifd_inf_t       ift_ifd_inf;
    ifd_id_inf_t        ifd_id_inf;
    ifd_ift_inf_t       ifd_ift_inf;
    wb_ix_inf_t         wb_ix_inf;
    // Outputs
    id_ix_inf_t         id_ix_inf;
    logic               ix_alu_valid, ix_lsu_tag_valid, ix_mul_valid, ix_div_valid;
    ix_alu_inf_t        ix_alu_inf;
    ix_lsu_tag_inf_t    ix_lsu_tag_inf;
    ix_mul_inf_t        ix_mul_inf;
    ix_div_inf_t        ix_div_inf;

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

    instruction_issue ix(.*);

    initial begin
        wb_do_branch <= 1'b0;
        wb_icache_invalidate <= 1'b0;
        wb_ix_inf.wr_en <= 1'b0;
        @(negedge rst);

        repeat(40) @(posedge clk);

        // Writeback has arrived
        wb_ix_inf.wr_en <= 1'b1;
        wb_ix_inf.rd <= 32'ha;
        wb_ix_inf.wr_data <= 32'h1;
        @(posedge clk);
        wb_ix_inf.wr_en <= 1'b1;
        wb_ix_inf.rd <= 32'hb;
        wb_ix_inf.wr_data <= 32'h3;
        @(posedge clk);
        wb_ix_inf.wr_en <= 1'b1;
        wb_ix_inf.rd <= 32'hc;
        wb_ix_inf.wr_data <= 32'h5;
        @(posedge clk);
        wb_ix_inf.wr_en <= 1'b1;
        wb_ix_inf.rd <= 32'hd;
        wb_ix_inf.wr_data <= 32'hd;
        @(posedge clk);
        wb_ix_inf.wr_en <= 1'b0;

        repeat(5) @(posedge clk);

        wb_ix_inf.wr_en <= 1'b1;
        wb_ix_inf.rd <= 32'h5;
        wb_ix_inf.wr_data <= 32'hdeadbeef;
        @(posedge clk);
        wb_ix_inf.wr_en <= 1'b0;

        repeat(10) @(posedge clk);

        $finish;
    end
endmodule