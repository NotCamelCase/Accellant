`include "defines.svh"

import defines::*;

module instruction_issue
(
    input logic             clk, rst,
    // WB -> IX
    input logic             wb_do_branch,
    // IX -> IFT
    output logic            ix_stall_if,
    // ID -> IX
    input logic             id_valid,
    input id_ix_inf_t       id_ix_inf,
    // WB -> IX
    input wb_ix_inf_t       wb_ix_inf,
    // IX -> ALU
    output logic            ix_alu_valid,
    output ix_alu_inf_t     ix_alu_inf,
    // IX -> LST
    output logic            ix_lst_valid,
    output ix_lst_inf_t     ix_lst_inf,
    // LSD -> IX
    input logic             lsd_dcache_flush_done,
    // IX -> MUL
    output logic            ix_mul_valid,
    output ix_mul_inf_t     ix_mul_inf,
    // IX -> DIV
    output logic            ix_div_valid,
    output ix_div_inf_t     ix_div_inf,
    // DIV -> IX
    input logic             div_ix_done
);
    // Max number of decoded instructions queued up to be issued (must be PoT!)
    localparam  IQ_LENGTH               = 8;

    // Should be equal the depth of IFT -> IX pipe
    localparam  IQ_STALL_IF_THRESHOLD   = IQ_LENGTH - 4;

    // EXE unit latencies
    localparam  EXE_ALU_LATENCY         = 1;
    localparam  EXE_LSU_LATENCY         = 2;
    localparam  EXE_MUL_LATENCY         = 3;

    // Architectural register file
    logic[31:0]                     reg_file[NUM_REGS-1:0];

    // Scoreboard
    logic                           sb_conflict;
    logic[NUM_REGS-1:0]             sb_gpr_reg;
    logic[NUM_REGS-1:0]             sb_deps_bits, sb_rd_bits, sb_wb_bits;
    logic[2*REG_WIDTH-1:0]          sb_pending_wb_rd_reg;

    logic                           iq_empty;
    logic                           next_instruction_valid;
    id_ix_inf_t                     next_instruction;
    logic                           fire_instruction;
    logic                           nop_instr, alu_instr, lsu_instr, mul_instr, div_instr;

    // WB confict logic
    logic                           wb_conflict;
    logic                           wb_alu_conflict, wb_lsu_conflict, wb_mul_conflict;
    logic[EXE_LSU_LATENCY-1:0]      wb_lsu_latency_reg;
    logic[EXE_MUL_LATENCY-1:0]      wb_mul_latency_reg;

    logic                           issue_div_op, issue_lsu_op;
    logic                           div_pending_op_reg, dcache_flush_pending_op_reg;

    initial begin
        // Zero out x0
        reg_file[0] = '0;
    end

    basic_fifo #(.ADDR_WIDTH($clog2(IQ_LENGTH)), .DATA_WIDTH($bits(id_ix_inf_t)), .ALMOST_FULL_THRESHOLD(IQ_STALL_IF_THRESHOLD)) iq(
        .clk(clk),
        .rst(rst),
        .clear(wb_do_branch), // On a branch, flush the IQ because all previously decoded instructions are invalid now.
        .push(id_valid && !wb_do_branch),
        .pop(fire_instruction && !iq_empty),
        .empty(iq_empty),
        .full(),
        .almost_empty(),
        .almost_full(ix_stall_if), // Stall IF if instructions can't be issued because IQ is almost full
        .rd_data(next_instruction), // Next instruction to be dispatched to EXE units
        .wr_data(id_ix_inf)); // New decoded instruction

    assign next_instruction_valid = !iq_empty;

    assign nop_instr = ~(|next_instruction.exe_pipe);
    assign alu_instr = next_instruction.exe_pipe[EXE_PIPE_ID_ALU];
    assign lsu_instr = next_instruction.exe_pipe[EXE_PIPE_ID_LSU];
    assign mul_instr = next_instruction.exe_pipe[EXE_PIPE_ID_MUL];
    assign div_instr = next_instruction.exe_pipe[EXE_PIPE_ID_DIV];

    // Write-back to register file
    always_ff @(posedge clk) begin
        if (wb_ix_inf.wr_en)
            reg_file[wb_ix_inf.rd] <= wb_ix_inf.wr_data;
    end

    // SB registers
    always_ff @(posedge clk) begin
        if (rst)
            sb_gpr_reg <= '0;
        else
            sb_gpr_reg <= (sb_gpr_reg & (~sb_wb_bits)) | (sb_rd_bits & {NUM_REGS{~nop_instr}});
    end

    // Handle pending WB after a branch invalidation
    always_ff @(posedge clk) begin
        if (rst || wb_do_branch)
            sb_pending_wb_rd_reg <= '0;
        else if (next_instruction_valid && !nop_instr)
            sb_pending_wb_rd_reg <= {sb_pending_wb_rd_reg[REG_WIDTH-1:0], next_instruction.rd & {REG_WIDTH{sb_gpr_reg[next_instruction.rd] == 1'b0}}};
    end

    // Set bit for used GPRs
    always_comb begin
        sb_deps_bits = '0;
        sb_deps_bits[next_instruction.rd] = 1'b1;
        sb_deps_bits[next_instruction.a1] = 1'b1;
        sb_deps_bits[next_instruction.a2] = 1'b1;
    end

    // Set bit for used DST
    always_comb begin
        sb_rd_bits = '0;

        if (next_instruction.register_write)
            sb_rd_bits[next_instruction.rd] = next_instruction_valid && !wb_do_branch && fire_instruction;
    end

    // Clear pending bit after write-back or branch misprediction
    always_comb begin
        sb_wb_bits = '0;

        // Clear the last RD after a branch has been taken
        // LSU requires two slots for WB rd invalidation -- why?
            // The first LSU instruction to branch due to D$ miss is replayed at a later time, but has its rd recorded pending in SB,
            // and then comes the next instruction, which might happen to be another LSU instruction. With only a single rd tracked,
            // the first LSU that we branched off of, to replay again (re-try for D$ hit), would now hang because writeback for that rd won't ever come because it was dropped before WB at LST
        sb_wb_bits[sb_pending_wb_rd_reg[REG_WIDTH-1:0]] = wb_do_branch;
        sb_wb_bits[sb_pending_wb_rd_reg[2*REG_WIDTH-1:REG_WIDTH]] = wb_do_branch;

        // Write-back has arrived
        if (wb_ix_inf.wr_en)
            sb_wb_bits[wb_ix_inf.rd] = 1'b1;
    end

    // Determine SB conflicts
    assign sb_conflict = |(sb_gpr_reg & sb_deps_bits);

    // Determine WB conflicts
    always_ff @(posedge clk) begin
        if (rst) begin
            wb_lsu_latency_reg <= '0;
            wb_mul_latency_reg <= '0;
        end else begin
            wb_lsu_latency_reg <= {wb_lsu_latency_reg[EXE_LSU_LATENCY-2:0], (next_instruction_valid && lsu_instr)};
            wb_mul_latency_reg <= {wb_mul_latency_reg[EXE_MUL_LATENCY-2:0], (next_instruction_valid && mul_instr)};
        end
    end

    assign wb_alu_conflict = wb_lsu_latency_reg[EXE_LSU_LATENCY-EXE_ALU_LATENCY-1] ||
                             wb_mul_latency_reg[EXE_MUL_LATENCY-EXE_ALU_LATENCY-1];
    assign wb_lsu_conflict = wb_mul_latency_reg[EXE_MUL_LATENCY-EXE_LSU_LATENCY-1];
    assign wb_mul_conflict = 1'b0; // MUL is the longest EXE pipe currently

    assign wb_conflict = (alu_instr && wb_alu_conflict) ||
                         (lsu_instr && wb_lsu_conflict) ||
                         (mul_instr && wb_mul_conflict);

    assign issue_div_op = div_instr && next_instruction_valid && !wb_do_branch && fire_instruction;
    assign issue_lsu_op = lsu_instr && next_instruction_valid && !wb_do_branch && fire_instruction;

    // Track pending DIV ops
    always_ff @(posedge clk) begin
        if (rst)
            div_pending_op_reg <= 1'b0;
        else if (!div_pending_op_reg)
            div_pending_op_reg <= issue_div_op;
        else if (div_ix_done || wb_do_branch)
            div_pending_op_reg <= 1'b0;
    end

    // Track pending D$ flush op
    always_ff @(posedge clk) begin
        if (rst)
            dcache_flush_pending_op_reg <= 1'b0;
        else if (!dcache_flush_pending_op_reg)
            dcache_flush_pending_op_reg <= issue_lsu_op && next_instruction.dcache_flush;
        else if (lsd_dcache_flush_done || wb_do_branch)
            dcache_flush_pending_op_reg <= 1'b0;
    end

    assign fire_instruction = !sb_conflict && !wb_conflict && !div_pending_op_reg && !dcache_flush_pending_op_reg;

    always_ff @(posedge clk) ix_alu_valid <= alu_instr && next_instruction_valid && !wb_do_branch && fire_instruction;

    // Outputs to ALU
    always_ff @(posedge clk) begin
        ix_alu_inf.register_write <= next_instruction.register_write;
        ix_alu_inf.branch <= next_instruction.branch;
        ix_alu_inf.jump <= next_instruction.jal || next_instruction.jalr;
        ix_alu_inf.branch_op <= next_instruction.branch_op;
        ix_alu_inf.icache_invalidate <= next_instruction.icache_invalidate;
        ix_alu_inf.result_src <= next_instruction.result_src;
        ix_alu_inf.alu_control <= next_instruction.alu_control;
        ix_alu_inf.rs1 <= reg_file[next_instruction.a1];
        // Bake imm_ext into rs2 for simple ALU operations
        // imm_ext in ALU is still needed for:
            // 1) branch/jump
            // 2) LUI & AUIPC instructions
        ix_alu_inf.rs2 <= next_instruction.alu_src ? next_instruction.imm_ext : reg_file[next_instruction.a2];
        ix_alu_inf.rd <= next_instruction.rd;
        ix_alu_inf.pc <= next_instruction.pc;
        ix_alu_inf.pc_inc <= next_instruction.pc_inc;
        ix_alu_inf.pc_base <= next_instruction.jalr ? reg_file[next_instruction.a1] : next_instruction.pc;
        ix_alu_inf.imm_ext <= next_instruction.imm_ext;
    end

    always_ff @(posedge clk) ix_lst_valid <= issue_lsu_op;

    // Outputs to LSU
    always_ff @(posedge clk) begin
        ix_lst_inf.rd <= next_instruction.rd;
        ix_lst_inf.register_write <= next_instruction.register_write;
        ix_lst_inf.mem_store <= next_instruction.mem_store;
        ix_lst_inf.mem_load <= next_instruction.mem_load;
        ix_lst_inf.dcache_invalidate <= next_instruction.dcache_invalidate;
        ix_lst_inf.dcache_flush <= next_instruction.dcache_flush;
        ix_lst_inf.lsu_control <= next_instruction.lsu_control;
        ix_lst_inf.write_data <= reg_file[next_instruction.a2];
        ix_lst_inf.rs1 <= reg_file[next_instruction.a1];
        ix_lst_inf.imm_ext <= next_instruction.imm_ext;
        ix_lst_inf.pc <= next_instruction.pc;
    end

    always_ff @(posedge clk) ix_mul_valid <= mul_instr && next_instruction_valid && !wb_do_branch && fire_instruction;

    // Outputs to MUL
    always_ff @(posedge clk) begin
        ix_mul_inf.mul_control <= next_instruction.mul_control;
        ix_mul_inf.rd <= next_instruction.rd;
        // No immediates; MUL operates only on registers.
        ix_mul_inf.rs1 <= reg_file[next_instruction.a1];
        ix_mul_inf.rs2 <= reg_file[next_instruction.a2];
    end

    always_ff @(posedge clk) ix_div_valid <= issue_div_op;

    // Outputs to DIV
    always_ff @(posedge clk) begin
        ix_div_inf.div_control <= next_instruction.div_control;
        ix_div_inf.rd <= next_instruction.rd;
        // No immediates; DIV operates only on registers
        ix_div_inf.rs1 <= reg_file[next_instruction.a1];
        ix_div_inf.rs2 <= reg_file[next_instruction.a2];
    end
endmodule