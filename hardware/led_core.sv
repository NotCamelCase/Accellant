`include "defines.svh"
`include "memory_map.svh"

import defines::*;

module led_core
#(parameter NUM_LEDS = 4)
(
    input logic                 clk, rst,
    // IO Interconnect -> LED
    input logic                 io_bus_s_rd_en,
    input logic                 io_bus_s_wr_en,
    input logic                 io_bus_s_cs,
    input logic[31:0]           io_bus_s_address,
    input logic[31:0]           io_bus_s_wr_data,
    // LED -> IO Interconnect
    output logic[NUM_LEDS-1:0]  led
);
    logic[NUM_LEDS-1:0] led_reg;

    always_ff @(posedge clk) begin
        if (rst)
            led_reg <= {NUM_LEDS{1'b0}};
        else if (io_bus_s_cs && io_bus_s_wr_en) begin
            unique case (io_bus_s_address[7:0])
                MMIO_LED_REG_SET_LED: led_reg <= io_bus_s_wr_data[NUM_LEDS-1:0];
                default: ;
            endcase
        end
    end

    // Outputs
    assign led = led_reg;
endmodule