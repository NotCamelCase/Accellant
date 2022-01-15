`ifndef __DEFINES_SVH__
`define __DEFINES_SVH__

typedef enum logic[3:0] {
    ALU_OP_ADD      = 4'b0000,
    ALU_OP_SUB      = 4'b1000,
    ALU_OP_SLL      = 4'b0001,
    ALU_OP_LT       = 4'b0010,
    ALU_OP_LTU      = 4'b0011,
    ALU_OP_XOR      = 4'b0100,
    ALU_OP_SRL      = 4'b0101,
    ALU_OP_SRA      = 4'b1101,
    ALU_OP_OR       = 4'b0110,
    ALU_OP_AND      = 4'b0111,
    ALU_OP_LUI      = 4'b1111,
    ALU_OP_AUIPC    = 4'b1110
} alu_op_e;

// WB result mux selector
typedef enum logic[1:0] {
    WB_SRC_ALU       = 2'b00,
    WB_SRC_MEM_READ  = 2'b01,
    WB_SRC_PC_INC    = 2'b10
} wb_src_e;

// Instruction immediate type
typedef enum logic[2:0] {
    IMM_TYPE_I  = 3'b000,
    IMM_TYPE_S  = 3'b001,
    IMM_TYPE_B  = 3'b010,
    IMM_TYPE_J  = 3'b011,
    IMM_TYPE_SH = 3'b100,
    IMM_TYPE_U  = 3'b101
} imm_type_e;

// Branch op
typedef enum logic[2:0] {
    BEQ     = 3'b000,
    BNE     = 3'b001,
    BLT     = 3'b100,
    BGE     = 3'b101,
    BLTU    = 3'b110,
    BGEU    = 3'b111
} branch_op_e;

// Bypass selectors
typedef enum logic[1:0] { 
    BYPASS_REG_FILE     = 2'b00,
    BYPASS_WRITEBACK    = 2'b01,
    BYPASS_MEMORY       = 2'b10
 } bypass_src_e;

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
    branch_op_e branch_op;
    wb_src_e    result_src;
    logic       mem_store;
    logic       mem_load;
    alu_op_e    alu_control;
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
    logic       branch_taken;
    wb_src_e    result_src;
    logic       mem_store;
    logic       mem_load;
} mem_ctrl_t;

// EXE -> MEM
typedef struct packed {
    logic[4:0]  rd;
    logic[31:0] alu_result;
    logic[31:0] write_data;
    logic[31:0] branch_target;
    logic[31:0] pc_inc;
    mem_ctrl_t  ctrl;
} exe_mem_inf_t;

// MEM -> WB control signals
typedef struct packed {
    logic   mem_load;
    logic   register_write;
    logic   result_src;
} wb_ctrl_t;

// MEM -> WB
typedef struct packed {
    logic[4:0]  rd;
    logic[31:0] alu_result_or_pc_inc;
    logic[31:0] read_data;
    wb_ctrl_t   ctrl;
} mem_wb_inf_t;

// WB -> ID data path
typedef struct packed {
    logic       wr_en;
    logic[4:0]  rd;
    logic[31:0] wr_data;
} wb_id_inf_t;

`endif