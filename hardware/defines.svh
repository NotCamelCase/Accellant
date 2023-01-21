`ifndef __DEFINES_SVH__
`define __DEFINES_SVH__

package defines;

// Number of scalar registers
localparam  XLEN                    = 32;

// Number of floating-point registers
localparam  FLEN                    = 32;

// Total number of GPRs
//TODO: + FLEN for FPU!
localparam  NUM_REGS                = XLEN;
localparam  REG_WIDTH               = $clog2(NUM_REGS);

// Number of execution pipes
//TODO: FPU + CSR?!
localparam   NUM_EXE_PIPES          = 4; // ALU + LSU + MUL + DIV

// EXE pipe IDs, which also designate fixed arbitration priority at WB
localparam  EXE_PIPE_ID_ALU         = 0;
localparam  EXE_PIPE_ID_LSU         = 1;
localparam  EXE_PIPE_ID_MUL         = 2;
localparam  EXE_PIPE_ID_DIV         = 3;

// I$ - 4k
localparam  ICACHE_NUM_WAYS         = 4;
localparam  ICACHE_NUM_SETS         = 16;
localparam  ICACHE_CL_SIZE          = 64; // In bytes

localparam  ICACHE_NUM_BLOCK_BITS   = $clog2(ICACHE_CL_SIZE);
localparam  ICACHE_NUM_SET_BITS     = $clog2(ICACHE_NUM_SETS);
localparam  ICACHE_NUM_TAG_BITS     = 32 - (ICACHE_NUM_BLOCK_BITS + ICACHE_NUM_SET_BITS);
localparam  ICACHE_NUM_WAY_BITS     = $clog2(ICACHE_NUM_WAYS);

// D$ - 16k
localparam  DCACHE_NUM_WAYS         = 4;
localparam  DCACHE_NUM_SETS         = 64;
localparam  DCACHE_CL_SIZE          = 64; // In bytes

localparam  DCACHE_NUM_BLOCK_BITS   = $clog2(DCACHE_CL_SIZE);
localparam  DCACHE_NUM_SET_BITS     = $clog2(DCACHE_NUM_SETS);
localparam  DCACHE_NUM_TAG_BITS     = 32 - (DCACHE_NUM_BLOCK_BITS + DCACHE_NUM_SET_BITS);
localparam  DCACHE_NUM_WAY_BITS     = $clog2(DCACHE_NUM_WAYS);

typedef struct packed {
    logic[ICACHE_NUM_TAG_BITS-1:0]      tag_idx;
    logic[ICACHE_NUM_SET_BITS-1:0]      set_idx;
    logic[ICACHE_NUM_BLOCK_BITS-1:0]    block_idx;
} ifu_address_t;

typedef struct packed {
    logic[DCACHE_NUM_TAG_BITS-1:0]      tag_idx;
    logic[DCACHE_NUM_SET_BITS-1:0]      set_idx;
    logic[DCACHE_NUM_BLOCK_BITS-1:0]    block_idx;
} lsu_address_t;

typedef logic[ICACHE_NUM_TAG_BITS-1:0]  icache_tag_t;
typedef logic[DCACHE_NUM_TAG_BITS-1:0]  dcache_tag_t;

// Parallel execution units
typedef enum logic[NUM_EXE_PIPES-1:0] {
    EXE_PIPE_INVALID    = 0,
    EXE_PIPE_ALU        = 1 << EXE_PIPE_ID_ALU,
    EXE_PIPE_LSU        = 1 << EXE_PIPE_ID_LSU,
    EXE_PIPE_MUL        = 1 << EXE_PIPE_ID_MUL,
    EXE_PIPE_DIV        = 1 << EXE_PIPE_ID_DIV
} exe_pipe_e;

// RV32I opcodes
typedef enum logic[6:0] {
    // ALU opcodes
    INSTR_OPCODE_ALU_MUL_DIV_R  = 7'b0110011,   // Simple ALU + MUL + DIV ops
    INSTR_OPCODE_ALU_BRANCH     = 7'b1100011,   // Conditional branch ops
    INSTR_OPCODE_ALU_I          = 7'b0010011,   // rs1 + immediate ALU ops
    INSTR_OPCODE_ALU_JALR       = 7'b1100111,   // Jump-and-link-register op
    INSTR_OPCODE_ALU_JAL        = 7'b1101111,   // Jump-and-link op
    INSTR_OPCODE_ALU_LUI        = 7'b0110111,   // LUIPC
    INSTR_OPCODE_ALU_AUIPC      = 7'b0010111,   // AUIPC
    // LSU opcodes
    INSTR_OPCODE_LSU_LOAD       = 7'b0000011,   // Memory load ops
    INSTR_OPCODE_LSU_STORE      = 7'b0100011,   // Memory store ops
    INSTR_OPCODE_FENCE          = 7'b0001111    // fence.i
    // 7'b1110011 -> ECALL/EBREAK
} instr_opcode_e;

// ALU ops
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

// MUL ops
typedef enum logic[1:0] {
    MUL_OP_MUL      = 2'b00,
    MUL_OP_MULH     = 2'b01,
    MUL_OP_MULHSU   = 2'b10,
    MUL_OP_MULHU    = 2'b11
} mul_op_e;

// DIV ops
typedef enum logic[1:0] {
    DIV_OP_DIV  = 2'b00,
    DIV_OP_DIVU = 2'b01,
    DIV_OP_REM  = 2'b10,
    DIV_OP_REMU = 2'b11
} div_op_e;

// Immediate encodings
typedef enum logic[2:0] {
    IMM_TYPE_I  = 3'b000,
    IMM_TYPE_S  = 3'b001,
    IMM_TYPE_B  = 3'b010,
    IMM_TYPE_J  = 3'b011,
    IMM_TYPE_SH = 3'b100,
    IMM_TYPE_U  = 3'b101
} imm_type_e;

// Branch ops
typedef enum logic[2:0] {
    BRANCH_OP_BEQ   = 3'b000,
    BRANCH_OP_BNE   = 3'b001,
    BRANCH_OP_BLT   = 3'b100,
    BRANCH_OP_BGE   = 3'b101,
    BRANCH_OP_BLTU  = 3'b110,
    BRANCH_OP_BGEU  = 3'b111
} branch_op_e;

// Load ops
typedef enum logic[2:0] {
    LOAD_OP_LB  = 3'b000,
    LOAD_OP_LH  = 3'b001,
    LOAD_OP_LW  = 3'b010,
    LOAD_OP_LBU = 3'b100,
    LOAD_OP_LHU = 3'b101
} load_op_e;

// Store ops
typedef enum logic[1:0] {
    STORE_OP_SB = 2'b00,
    STORE_OP_SH = 2'b01,
    STORE_OP_SW = 2'b10
} store_op_e;

// IFT -> IFD
typedef struct packed {
    ifu_address_t                       fetched_pc;
    logic[ICACHE_NUM_WAYS-1:0]          valid_bits;
    icache_tag_t[ICACHE_NUM_WAYS-1:0]   tags_read;
} ift_ifd_inf_t;

// IFD -> IFT
typedef struct packed {
    logic                           cache_miss;
    logic                           resume_fetch;
    logic[ICACHE_NUM_WAYS-1:0]      update_tag_en;
    logic[ICACHE_NUM_SET_BITS-1:0]  update_tag_set;
    icache_tag_t                    update_tag;
} ifd_ift_inf_t;

// IFD -> ID
typedef struct packed {
    logic[31:0] pc;
    logic[31:0] pc_inc;
    logic[31:0] instr;
} ifd_id_inf_t;

// ID -> IX
typedef struct packed {
    logic[REG_WIDTH-1:0]    a1;
    logic[REG_WIDTH-1:0]    a2;
    logic[REG_WIDTH-1:0]    rd;
    logic[31:0]             pc;
    logic[31:0]             pc_inc;
    logic[31:0]             imm_ext;
    logic                   register_write;
    logic                   branch, jal, jalr;
    branch_op_e             branch_op;
    logic                   result_src;
    logic                   mem_store;
    logic                   mem_load;
    logic                   icache_invalidate;
    alu_op_e                alu_control;
    mul_op_e                mul_control;
    div_op_e                div_control;
    logic[2:0]              lsu_control;
    logic                   alu_src;
    exe_pipe_e              exe_pipe;
} id_ix_inf_t;

// IX -> ALU
typedef struct packed {
    logic                   icache_invalidate;
    logic                   register_write;
    logic                   branch, jump;
    branch_op_e             branch_op;
    logic                   result_src;
    alu_op_e                alu_control;
    logic[REG_WIDTH-1:0]    rd;
    logic[31:0]             pc;
    logic[31:0]             pc_inc;
    logic[31:0]             pc_base;
    logic[31:0]             rs1;
    logic[31:0]             rs2;
    logic[31:0]             imm_ext;
} ix_alu_inf_t;

// IX -> LST
typedef struct packed {
    logic[REG_WIDTH-1:0]    rd;
    logic                   register_write;
    logic                   mem_store;
    logic                   mem_load;
    logic                   dcache_flush;
    logic                   dcache_invalidate;
    logic[2:0]              lsu_control;
    logic[31:0]             write_data;
    logic[31:0]             rs1;
    logic[31:0]             imm_ext;
    logic[31:0]             pc;
} ix_lst_inf_t;

// LST -> LSD
typedef struct packed {
    logic                               register_write;
    logic                               mem_store;
    logic                               mem_load;
    logic                               dcache_flush;
    logic                               dcache_invalidate;
    logic                               cacheable_mem_access;
    logic[REG_WIDTH-1:0]                rd;
    lsu_address_t                       mem_addr;
    load_op_e                           mem_load_op;
    logic[3:0]                          write_strobe;
    logic[31:0]                         write_data;
    logic[31:0]                         pc;
    logic[DCACHE_NUM_WAYS-1:0]          valid_bits;
    dcache_tag_t[DCACHE_NUM_WAYS-1:0]   tags_read;
    logic                               io_rd_en;
    logic                               io_wr_en;
} lst_lsd_inf_t;

// LSD -> LST
typedef struct packed {
    logic[DCACHE_NUM_WAYS-1:0]      update_tag_en;
    logic[DCACHE_NUM_SET_BITS-1:0]  update_tag_set;
    logic[DCACHE_NUM_SET_BITS-1:0]  evict_set;
    dcache_tag_t                    update_tag;
} lsd_lst_inf_t;

// IX -> MUL
typedef struct packed {
    logic[REG_WIDTH-1:0]    rd;
    logic[31:0]             rs1;
    logic[31:0]             rs2;
    mul_op_e                mul_control;
} ix_mul_inf_t;

// IX -> DIV
typedef struct packed {
    logic[REG_WIDTH-1:0]    rd;
    logic[31:0]             rs1;
    logic[31:0]             rs2;
    div_op_e                div_control;
} ix_div_inf_t;

// ALU -> WB
typedef struct packed {
    logic                   do_branch;
    logic                   icache_invalidate;
    logic[31:0]             branch_target;
    logic                   register_write;
    logic[REG_WIDTH-1:0]    rd;
    logic[31:0]             exe_result;
} alu_wb_inf_t;

// LSD -> WB
typedef struct packed {
    logic                   do_branch;
    logic                   register_write;
    logic[1:0]              load_selector;
    load_op_e               load_control;
    logic[REG_WIDTH-1:0]    rd;
    logic[31:0]             load_result;
    logic[31:0]             branch_target;
} lsd_wb_inf_t;

// MUL -> WB
typedef struct packed {
    logic[4:0]  rd;
    logic[31:0] result;
} mul_wb_inf_t;

// DIV -> WB
typedef struct packed {
    logic[4:0]  rd;
    logic[31:0] result;
} div_wb_inf_t;

// WB -> IX
typedef struct packed {
    logic                   wr_en;
    logic[REG_WIDTH-1:0]    rd;
    logic[31:0]             wr_data;
} wb_ix_inf_t;

endpackage

`endif