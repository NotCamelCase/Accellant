`timescale 1ns/1ps

module tb_uart
(
);
    // Clock period
    localparam T = 10;

    // Inputs
    logic       clk; // 10 ns
    logic       rst; // Sync reset active-high
    logic       io_bus_s_rd_en;
    logic       io_bus_s_wr_en;
    logic[31:0] io_bus_s_address;
    logic[31:0] io_bus_s_wr_data;
    logic       uart_rx;
    // Outputs
    logic       uart_tx;
    logic[31:0] rd_dat;
    logic[31:0] rd_data;

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

    uart_core uart(.*);

    initial begin
        io_bus_s_wr_en <= 1'b0;
        io_bus_s_rd_en <= 1'b0;
        uart_rx <= 1'b1;
        @(negedge rst);

        repeat(10) @(posedge clk);

        // Transmit a single byte
        io_bus_s_wr_en <= 1'b1;
        io_bus_s_wr_data <= 32'b1010_0101;
        io_bus_s_address <= 32'hff00_020c; // UART[3] = wr_data
        @(posedge clk);
        io_bus_s_wr_en <= 1'b0;
        io_bus_s_wr_data <= 32'hdeadbeef;

        repeat(100000) @(posedge clk);

        $finish;
    end
endmodule