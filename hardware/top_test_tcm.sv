module top_test_tcm
(
    input logic         clk100,
    input logic         arstn,
    output logic[3:0]   led,
    output logic        uart_rx,
    input logic         uart_tx
);
    localparam  LED_COUNT   = 4;

    logic       clk;
    logic       rst;

    assign clk = clk100;

    sync_reset reset(
    	.clk(clk),
        .arstn(arstn),
        .rst(rst));

    accellant_soc_tcm #(.LED_COUNT(LED_COUNT)) soc(.*);
endmodule