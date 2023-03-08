`timescale 1ns/1ps

module tb_accellant_soc
(
);
    // Clock period
    localparam  T = 10;

    localparam  LED_COUNT   = 8;

    // Inputs
    logic                   clk; // 10 ns
    logic                   rst; // Sync reset active-high
    logic                   uart_tx;
    // Outputs
    logic[LED_COUNT-1:0]    led;
    logic                   uart_rx;

    always begin
        clk = 1'b1;
        #(T/2);
        clk = 1'b0;
        #(T/2);
    end

    initial begin
        rst = 1'b1;
        #(10*T);
        rst = 1'b0;
    end

    accellant_soc #(.LED_COUNT(LED_COUNT)) soc(.*);

    initial begin
        uart_tx <= 1'b1;
        @(negedge rst);

        repeat(350000) @(posedge clk);

        $finish;
    end
endmodule