`include "defines.svh"

import defines::*;

module io_interconnect
(
    input logic                     clk, rst,
    // Core -> IO Interconnect
    input logic                     io_bus_m_rd_en,
    input logic                     io_bus_m_wr_en,
    input logic[NUM_IO_CORES-1:0]   io_bus_m_cs,
    input logic[31:0]               io_bus_m_address,
    input logic[31:0]               io_bus_m_wr_data,
    // IO Interconnect -> Core
    output logic[31:0]              io_bus_m_rd_data,
    // Core -> IO Interconnect
    input logic[31:0]               io_bus_timer_rd_data,
    input logic[31:0]               io_bus_uart_rd_data,
    // IO Interconnect -> Core
    output logic                    io_bus_s_rd_en,
    output logic                    io_bus_s_wr_en,
    output logic[NUM_IO_CORES-1:0]  io_bus_s_cs,
    output logic[31:0]              io_bus_s_address,
    output logic[31:0]              io_bus_s_wr_data
);
    logic[$clog2(NUM_IO_CORES)-1:0] cs_reg, cs_nxt;
    logic[31:0]                     cores_rd_data_array[NUM_IO_CORES-1:0];

    // Register chip-select value converted from one-hot to binary to return enabled IO core's read data
    always_ff @(posedge clk) cs_reg <= cs_nxt;

    always_comb begin
        cs_nxt = '0;

        for (int index = 0; index < NUM_IO_CORES; index++) begin
            if (io_bus_m_cs[index])
                cs_nxt |= index[$clog2(NUM_IO_CORES)-1:0];
        end
    end

    assign cores_rd_data_array[0] = '0; // Slot #0 = LED
    assign cores_rd_data_array[1] = io_bus_timer_rd_data; // Slot #1 = Timer
    assign cores_rd_data_array[2] = io_bus_uart_rd_data; // Slot #2 = UART

    // Outputs
    assign io_bus_s_rd_en = io_bus_m_rd_en;
    assign io_bus_s_wr_en = io_bus_m_wr_en;
    assign io_bus_s_cs = io_bus_m_cs;
    assign io_bus_s_address = io_bus_m_address;
    assign io_bus_s_wr_data = io_bus_m_wr_data;
    assign io_bus_m_rd_data = cores_rd_data_array[cs_reg];
endmodule