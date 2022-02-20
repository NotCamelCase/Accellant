`timescale 1ns/1ps

module tb_riscv_core
(
);
    // Clock period
    localparam T = 10;

    // Inputs
    logic       clk; // 10 ns
    logic       rst; // Sync reset active-high
    // Outputs
    logic[3:0]  led;

    always begin
        clk = `TRUE;
        #(T/2);
        clk = `FALSE;
        #(T/2);
    end

    initial begin
        rst = `TRUE;
        #(T/2);
        rst = `FALSE;
    end

    riscv_core #(.TEST_PROG("complex_mul.mem")) core(
        .clk(clk),
        .rst(rst),
        .led(led));

    initial begin
        @(negedge rst);
        
        @(negedge clk);

        repeat(3000) @(negedge clk);

        $finish;
    end
endmodule