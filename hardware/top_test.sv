module top_test
(
    input logic         clk,
    input logic         arst,
    output logic[3:0]   led,
    output logic        uart_rx,
    input logic         uart_tx
);
    logic   rst; // Active-high sync reset

    sync_reset sync_rst(.*);

    accellant_soc soc(.*);
endmodule