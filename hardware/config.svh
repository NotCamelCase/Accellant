`ifndef __CONFIG_SVH__
`define __CONFIG_SVH__

`include "defines.svh"

// Toggle forwarding result from WB stage to save one cycle during Dispatch
parameter   ENABLE_BYPASS_WB    = `FALSE;

`endif