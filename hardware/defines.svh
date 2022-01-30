`ifndef __DEFINES_SVH__
`define __DEFINES_SVH__

`define TRUE    1'b1
`define FALSE   1'b0

// Number of scalar registers
parameter   XLEN        = 32;

// Number of floating-point registers
parameter   FLEN        = 32;

// Total number of GPRs
//TODO: + FLEN for FPU!
parameter   NUM_REGS    = XLEN;
parameter   REG_WIDTH   = $clog2(NUM_REGS);

// Number of execution pipes
//TODO: MUL_DIV + FPU + CSR?!
parameter   NUM_EXE_PIPES       = 2; // ALU + LSU

// Execution pipes
typedef enum {
    EXE_PIPE_ALU_BIT    = 0,
    EXE_PIPE_LSU_BIT    = 1
} exe_pipe_e;

// RV32I opcodes
typedef enum logic[6:0] {
    // ALU opcodes
    INSTR_OPCODE_ALU_R         = 7'b0110011,
    INSTR_OPCODE_ALU_BRANCH    = 7'b1100011,
    INSTR_OPCODE_ALU_I         = 7'b0010011,
    INSTR_OPCODE_ALU_JALR      = 7'b1100111,
    INSTR_OPCODE_ALU_JAL       = 7'b1101111,
    INSTR_OPCODE_ALU_LUI       = 7'b0110111,
    INSTR_OPCODE_ALU_AUIPC     = 7'b0010111,
    // LSU opcodes
    INSTR_OPCODE_LSU_LOAD      = 7'b0000011,
    INSTR_OPCODE_LSU_STORE     = 7'b0100011
} instr_opcode_e;

// ALU op
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

    // 7'b0001111 -> FENCE
    // 7'b1110011 -> ECALL/EBREAK
} alu_op_e;

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
    BRANCH_OP_BEQ   = 3'b000,
    BRANCH_OP_BNE   = 3'b001,
    BRANCH_OP_BLT   = 3'b100,
    BRANCH_OP_BGE   = 3'b101,
    BRANCH_OP_BLTU  = 3'b110,
    BRANCH_OP_BGEU  = 3'b111
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

// ID -> DISPATCHER control signals
typedef struct packed {
    logic                       register_write;
    logic                       branch, jal, jalr;
    branch_op_e                 branch_op;
    logic                       result_src;
    logic                       mem_store;
    logic                       mem_load;
    alu_op_e                    alu_control;
    logic                       alu_src;
    logic[NUM_EXE_PIPES-1:0]    exe_pipe;
} dispatcher_ctrl_t;

// ID -> DISPATCHER
typedef struct packed {
    logic[REG_WIDTH-1:0]        a1;
    logic[REG_WIDTH-1:0]        a2;
    logic[REG_WIDTH-1:0]        rd;
    logic[31:0]                 pc;
    logic[31:0]                 pc_inc;
    logic[31:0]                 imm_ext;
    dispatcher_ctrl_t           ctrl;
} id_dispatcher_inf_t;

// DISPATCHER -> ALU control signals
typedef struct packed {
    logic       instruction_valid;
    logic       register_write;
    logic       branch, jal, jalr;
    branch_op_e branch_op;
    logic       result_src;
    logic       mem_store;
    logic       mem_load;
    alu_op_e    alu_control;
} alu_ctrl_t;

// DISPATCHER -> ALU
typedef struct packed {
    logic[REG_WIDTH-1:0]    rd;
    logic[31:0]             pc;
    logic[31:0]             pc_inc;
    logic[31:0]             rs1;
    logic[31:0]             rs2;
    logic[31:0]             imm_ext;
    alu_ctrl_t              ctrl;
} dispatcher_alu_inf_t;

// DISPATCHER -> MEM control signals
typedef struct packed {
    logic       instruction_valid;
    logic       register_write;
    logic       mem_store;
    logic       mem_load;
} mem_ctrl_t;

// DISPATCHER -> LSU
typedef struct packed {
    logic[REG_WIDTH-1:0]    rd;
    logic[31:0]             rs1;
    logic[31:0]             imm_ext;
    logic[31:0]             write_data;
    mem_ctrl_t              ctrl;
} dispatcher_lsu_inf_t;

// EXE -> WB
typedef struct packed {
    logic                   instruction_valid;
    logic                   register_write;
    logic[REG_WIDTH-1:0]    rd;
    logic[31:0]             exe_result;
} exe_wb_inf_t;

// WB -> DISPATCHER
typedef struct packed {
    logic                   wr_en;
    logic[REG_WIDTH-1:0]    rd;
    logic[31:0]             wr_data;
} wb_dispatcher_inf_t;

`endif