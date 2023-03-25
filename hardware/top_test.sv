module top_test
(
    input logic         clk,
    input logic         arst,
    output logic[3:0]   led,
    output logic        uart_rx,
    input logic         uart_tx
);
    localparam  LED_COUNT   = 4;

    logic   rst; // Active-high sync reset

    sync_reset sync_rst(.*);

    accellant_soc #(.LED_COUNT(LED_COUNT)) soc(.*);
endmodule