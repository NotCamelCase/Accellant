`ifndef __MEMORY_MAP_SVH__
`define __MEMORY_MAP_SVH__

localparam  AXI_XBAR_NUM_SLAVES         = 3; // AXI ibus + AXI dbus + VGA
localparam  AXI_XBAR_NUM_MASTERS        = 2; // RAM + ROM

localparam  CACHEABLE_BASE_ADDRESS      = 32'h0;

localparam  RAM_BASE_ADDRESS            = CACHEABLE_BASE_ADDRESS;
localparam  RAM_SIZE                    = 32'h1000_0000; // 256 MB

localparam  INSTR_ROM_BASE_ADDRESS      = RAM_BASE_ADDRESS + RAM_SIZE;
localparam  INSTR_ROM_SIZE              = 32'h1000; // 4 KB

localparam  MMIO_BASE_ADDRESS           = 32'hff00_0000;

localparam  MMIO_LED_BASE_ADDRESS       =  MMIO_BASE_ADDRESS + 'h0;   // Slot #0
localparam  MMIO_LED_REG_SET_LED        = 'h0;

localparam  MMIO_TIMER_BASE_ADDRESS     = MMIO_BASE_ADDRESS + 'h100; // Slot #1
localparam  MMIO_TIMER_GET_CYCLE_CTR    = 'h0;

localparam  MMIO_UART_BASE_ADDRESS      = MMIO_BASE_ADDRESS + 'h200; // Slot #2
localparam  MMIO_UART_REG_GET_DATA          = 'h0;
localparam  MMIO_UART_REG_SET_BAUD_RATE     = 'h4;
localparam  MMIO_UART_REG_GET_STATUS        = 'h8;
localparam  MMIO_UART_REG_WRITE_DATA        = 'hc;

localparam  MMIO_VGA_BASE_ADDRESS       = MMIO_BASE_ADDRESS + 'h300; // Slot #3
localparam  MMIO_VGA_REG_SET_FB_BASE_ADDR   = 'h0;

`endif