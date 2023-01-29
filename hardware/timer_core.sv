`include "defines.svh"
`include "memory_map.svh"

import defines::*;

module timer_core
(
    input logic         clk, rst,
    // IO Interconnect -> Timer
    input logic         io_bus_s_rd_en,
    input logic         io_bus_s_wr_en,
    input logic         io_bus_s_cs,
    input logic[31:0]   io_bus_s_address,
    input logic[31:0]   io_bus_s_wr_data,
    // Timer -> IO Interconnect
    output logic[31:0]  rd_data
);
    // 32-bit cycle counter reg
    logic[31:0] timer_reg;

    always_ff @(posedge clk) begin
        if (rst)
            timer_reg <= '0;
        else
            timer_reg <= timer_reg + 32'h1;
    end

    assign rd_data = timer_reg;
endmodule