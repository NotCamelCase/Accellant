`include "defines.svh"
`include "memory_map.svh"

import defines::*;

module io_interconnect
(
    input logic         clk, rst,
    // Core -> IO Interconnect
    input logic         io_bus_m_rd_en,
    input logic         io_bus_m_wr_en,
    input logic[31:0]   io_bus_m_address,
    input logic[31:0]   io_bus_m_wr_data,
    // IO Interconnect -> Core
    output logic[31:0]  io_bus_m_rd_data,
    // Core -> IO Interconnect
    input logic[31:0]   io_bus_timer_rd_data,
    input logic[31:0]   io_bus_uart_rd_data,
    // IO Interconnect -> Core
    output logic        io_bus_s_rd_en,
    output logic        io_bus_s_wr_en,
    output logic[31:0]  io_bus_s_address,
    output logic[31:0]  io_bus_s_wr_data
);
    logic[1:0]  io_core_select_reg;
    logic[31:0] cores_rd_data_array[NUM_IO_CORES-1:0]; // Collection of read data signald from IO cores which route rd_data

    // Register read data MUX selector based on io_bus address
    always_ff @(posedge clk) begin
        unique case (io_bus_m_address[31:8])
            MMIO_TIMER_BASE_ADDRESS[31:8]:  io_core_select_reg <= 2'd0; // Timer core
            MMIO_UART_BASE_ADDRESS[31:8]:   io_core_select_reg <= 2'd1; // UART core
            default: ;
        endcase
    end

    assign cores_rd_data_array[0] = io_bus_timer_rd_data;
    assign cores_rd_data_array[1] = io_bus_uart_rd_data;

    // Outputs
    assign io_bus_s_rd_en = io_bus_m_rd_en;
    assign io_bus_s_wr_en = io_bus_m_wr_en;
    assign io_bus_s_address = io_bus_m_address;
    assign io_bus_s_wr_data = io_bus_m_wr_data;
    assign io_bus_m_rd_data = cores_rd_data_array[io_core_select_reg];
endmodule