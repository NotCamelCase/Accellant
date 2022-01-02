module top_test
(
    input logic         clk,
    input logic         arst,
    output logic[3:0]   led
);
    logic       rst; // Active-high sync reset

    sync_reset sync_rst(
        .clk(clk),
        .arst(arst),
        .rst(rst));
        
    riscv_core #(.TEST_PROG("complex_mul.mem")) cpu(
        .clk(clk),
        .rst(rst),
        .led(led));
endmodule