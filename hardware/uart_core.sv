`include "defines.svh"
`include "memory_map.svh"

import defines::*;

module uart_core
(
    input logic         clk, rst,
    // IO Interconnect -> UART
    input logic         io_bus_s_rd_en,
    input logic         io_bus_s_wr_en,
    input logic         io_bus_s_cs,
    input logic[31:0]   io_bus_s_address,
    input logic[31:0]   io_bus_s_wr_data,
    // SoC -> UART
    input logic         uart_rx,
    output logic        uart_tx,
    output logic[31:0]  rd_data
);
    localparam  UART_FIFO_LENGTH = 8;

    logic       baud_pulse;
    logic[10:0] divisor_reg;

    logic       remove_rx_data, insert_tx_data;
    logic       rx_done, tx_done;
    logic[7:0]  rx_data;
    logic[7:0]  rx_fifo_data, tx_fifo_data;

    logic       rx_empty, rx_full;
    logic       tx_empty, tx_full;

    // UART Core regs
    logic[10:0] baud_rate_reg; // BAUD rate

    always_ff @( posedge clk) begin
        if (rst)
            baud_rate_reg <= 11'd650; // Baud rate = 9600
        else if (io_bus_s_cs && io_bus_s_wr_en) begin
            unique case (io_bus_s_address[7:0])
                MMIO_UART_SET_BAUD_RATE: baud_rate_reg <= io_bus_s_wr_data[10:0];
                default: ;
            endcase
        end
    end

    // Read mux
    always_ff @(posedge clk) begin
        unique case (io_bus_s_address[7:0])
            MMIO_UART_GET_DATA: rd_data <= {24'h0, rx_fifo_data};
            MMIO_UART_GET_STATUS: rd_data <= {28'h0, tx_full, tx_empty, rx_full, rx_empty};
            default: ;
        endcase
    end

    always_ff @(posedge clk) begin
        if (rst)
            divisor_reg <= '0;
        else
            divisor_reg <= (divisor_reg == baud_rate_reg) ? 11'h0 : (divisor_reg + 11'h1);
    end

    // UART clock tick
    assign baud_pulse = (divisor_reg == 11'h1);

    // Remove an element from RX FIFO upon a data read
    assign remove_rx_data = io_bus_s_cs && io_bus_s_rd_en && (io_bus_s_address[7:0] == MMIO_UART_GET_DATA);
    // Insert an element to TX FIFO upon a data write
    assign insert_tx_data = io_bus_s_cs && io_bus_s_wr_en && (io_bus_s_address[7:0] == MMIO_UART_WRITE_DATA);

    uart_rx rx(
        .clk(clk),
        .rst(rst),
        .rx(uart_rx),
        .baud_pulse(baud_pulse),
        .uart_rx_done(rx_done),
        .rx_data(rx_data));

    // RX fifo
    basic_fifo #(
        // Queue up to UART_FIFO_LENGTH bytes
        .ADDR_WIDTH($clog2(UART_FIFO_LENGTH)),
        .DATA_WIDTH(8)) rx_fifo(
            .clk(clk),
            .rst(rst),
            .clear(1'b0),
            .push(rx_done),
            .pop (remove_rx_data),
            .empty(rx_empty),
            .full(rx_full),
            .almost_empty(),
            .almost_full(),
            .wr_data(rx_data),
            .rd_data(rx_fifo_data));

    uart_tx tx(
        .clk(clk),
        .rst(rst),
        .tx_start(~tx_empty),
        .baud_pulse(baud_pulse),
        .tx_data(tx_fifo_data),
        .uart_tx_done(tx_done),
        .tx(uart_tx));

    basic_fifo #(
        // Queue up to UART_FIFO_LENGTH bytes
        .ADDR_WIDTH($clog2(UART_FIFO_LENGTH)),
        .DATA_WIDTH(8)) tx_fifo(
            .clk(clk),
            .rst(rst),
            .clear(1'b0),
            .push(insert_tx_data),
            .pop (tx_done),
            .empty(tx_empty),
            .full(tx_full),
            .almost_empty(),
            .almost_full(),
            .wr_data(io_bus_s_wr_data[7:0]),
            .rd_data(tx_fifo_data));
endmodule