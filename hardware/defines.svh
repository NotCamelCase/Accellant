`ifndef __DEFINES_SVH__
`define __DEFINES_SVH__

// IF -> ID
typedef struct packed {
    logic[31:0] pc;
    logic[31:0] pc_inc;
    logic[31:0] instr;
} if_id_inf_t;

// ID -> EXE control signals
typedef struct packed {
    logic       register_write;
    logic       branch, jal, jalr;
    logic[2:0]  branch_op;
    logic[1:0]  result_src;
    logic       mem_store;
    logic       mem_load;
    logic[3:0]  alu_control;
    logic       alu_src;
} exe_ctrl_t;

// ID -> EXE
typedef struct packed {
    logic[4:0]  a1;
    logic[4:0]  a2;
    logic[4:0]  rd;
    logic[31:0] pc;
    logic[31:0] pc_inc;
    logic[31:0] rs1;
    logic[31:0] rs2;
    logic[31:0] imm_ext;
    exe_ctrl_t  ctrl;
} id_exe_inf_t;

// EXE -> MEM control signals
typedef struct packed {
    logic       register_write;
    logic[1:0]  result_src;
    logic       mem_store;
    logic       mem_load;
} mem_ctrl_t;

// EXE -> MEM
typedef struct packed {
    logic[31:0] alu_result;
    logic[31:0] write_data;
    logic[4:0]  rd;
    logic[31:0] pc_inc;
    mem_ctrl_t  ctrl;
} exe_mem_inf_t;

// MEM -> WB control signals
typedef struct packed {
    logic       mem_load;
    logic       register_write;
    logic[1:0]  result_src;
} wb_ctrl_t;

// MEM -> WB
typedef struct packed {
    logic[4:0]  rd;
    logic[31:0] alu_result;
    logic[31:0] read_data;
    logic[31:0] pc_inc;
    wb_ctrl_t   ctrl;
} mem_wb_inf_t;

// WB -> ID data path
typedef struct packed {
    logic       wr_en;
    logic[4:0]  rd;
    logic[31:0] wr_data;
} wb_id_inf_t;

`endif