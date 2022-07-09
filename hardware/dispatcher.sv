`include "defines.svh"

module dispatcher
(
    input logic                 clk, rst,
    // From Core
    input logic                 stall,
    input logic                 flush,
    // To Core
    output logic                dispatcher_conflict,
    output logic                div_stall,
    // From DIV
    input logic                 div_done,
    // From ID
    input id_dispatcher_inf_t   id_dispatcher_inf,
    // From WB
    input wb_dispatcher_inf_t   wb_dispatcher_inf,
    // To ALU
    output dispatcher_alu_inf_t dispatcher_alu_inf,
    // To LSU
    output dispatcher_lsu_inf_t dispatcher_lsu_inf,
    // To MUL
    output dispatcher_mul_inf_t dispatcher_mul_inf,
    // To DIV
    output dispatcher_div_inf_t dispatcher_div_inf
);
    //TODO: Re-org
    localparam  SP  = 32'h300;
    localparam  GP  = 32'h3ff;

    logic                           decoded_instruction_valid;
    logic                           fwd_rs1_wb, fwd_rs2_wb, fwd_rd_wb;

    // RS1/RS2 to be passed to EXE pipes
    logic[31:0]                     rs1, rs2;

    // Architectural register file
    logic[31:0]                     reg_file[NUM_REGS-1:0];

    // Scoreboard
    logic                           sb_conflict;
    logic[NUM_REGS-1:0]             sb_gpr_reg;
    logic[NUM_REGS-1:0]             sb_deps_bits, sb_rd_bits, sb_wb_bits;

    // Keep track of active instructions in different EXE pipes to resolve WB conflicts
    logic                           wb_conflict;
    logic[LATENCY_MUL_OP-1:0]       wb_active_mul_reg;

    logic                           div_stall_reg;

    // Initialize x0 and SP/GP for simulation
    initial begin
        reg_file[0] = 0;
        reg_file[2] = SP;
        reg_file[3] = GP;
    end

    // Write-back to register file
    always_ff @(posedge clk) begin
        if (wb_dispatcher_inf.wr_en)
            reg_file[wb_dispatcher_inf.rd] <= wb_dispatcher_inf.wr_data;
    end

    // Fetch operands
    assign rs1 = fwd_rs1_wb ? wb_dispatcher_inf.wr_data : reg_file[id_dispatcher_inf.a1];
    assign rs2 = fwd_rs2_wb ? wb_dispatcher_inf.wr_data : reg_file[id_dispatcher_inf.a2];

    // Decoded instruction is valid if no stall or flush occurs
    assign decoded_instruction_valid = id_dispatcher_inf.ctrl.instruction_valid & ~(stall | flush);

    // Propagate control signals to ALU
    always_ff @(posedge clk) begin
        if (flush)
            dispatcher_alu_inf.ctrl.instruction_valid <= `FALSE;
        else if (!stall)
            dispatcher_alu_inf.ctrl.instruction_valid <= decoded_instruction_valid & id_dispatcher_inf.ctrl.exe_pipe[`EXE_PIPE_ID_ALU];
    end

    always_ff @(posedge clk) begin
        if (flush) begin
            dispatcher_alu_inf.ctrl.register_write <= `FALSE;
            dispatcher_alu_inf.ctrl.branch <= `FALSE;
            dispatcher_alu_inf.ctrl.jump <= `FALSE;
            dispatcher_alu_inf.ctrl.branch_op <= BRANCH_OP_BEQ;
            dispatcher_alu_inf.ctrl.result_src <= `FALSE;
            dispatcher_alu_inf.ctrl.alu_control <= ALU_OP_ADD;
        end else if (!stall) begin
            dispatcher_alu_inf.ctrl.register_write <= id_dispatcher_inf.ctrl.register_write;
            dispatcher_alu_inf.ctrl.branch <= id_dispatcher_inf.ctrl.branch;
            dispatcher_alu_inf.ctrl.jump <= id_dispatcher_inf.ctrl.jal || id_dispatcher_inf.ctrl.jalr;
            dispatcher_alu_inf.ctrl.branch_op <= id_dispatcher_inf.ctrl.branch_op;
            dispatcher_alu_inf.ctrl.result_src <= id_dispatcher_inf.ctrl.result_src;
            dispatcher_alu_inf.ctrl.alu_control <= id_dispatcher_inf.ctrl.alu_control;
        end
    end

    always_ff @(posedge clk) begin
        dispatcher_alu_inf.rs1 <= rs1;

        // Bake imm_ext into rs2 for simple ALU operations
        // imm_ext in ALU is still needed for:
            // 1) branch/jump
            // 2) LUI & AUIPC instructions
        dispatcher_alu_inf.rs2 <= id_dispatcher_inf.ctrl.alu_src ? id_dispatcher_inf.imm_ext : rs2;
    end

    always_ff @(posedge clk) begin
        dispatcher_alu_inf.rd <= id_dispatcher_inf.rd;
        dispatcher_alu_inf.pc <= id_dispatcher_inf.pc;
        dispatcher_alu_inf.pc_inc <= id_dispatcher_inf.pc_inc;
        dispatcher_alu_inf.pc_base <= id_dispatcher_inf.ctrl.jalr ? rs1 : id_dispatcher_inf.pc;
        dispatcher_alu_inf.imm_ext <= id_dispatcher_inf.imm_ext;
    end

    // Propagate control signals to MEM
    always_ff @(posedge clk) begin
        if (flush)
            dispatcher_lsu_inf.ctrl.instruction_valid <= `FALSE;
        else if (!stall)
            dispatcher_lsu_inf.ctrl.instruction_valid <= decoded_instruction_valid & id_dispatcher_inf.ctrl.exe_pipe[`EXE_PIPE_ID_LSU];
    end

    always_ff @(posedge clk) begin
        if (flush) begin
            dispatcher_lsu_inf.ctrl.register_write <= `FALSE;
            dispatcher_lsu_inf.ctrl.mem_store <= `FALSE;
            dispatcher_lsu_inf.ctrl.mem_load <= `FALSE;
            dispatcher_lsu_inf.ctrl.lsu_control <= 3'b0;
        end else if (!stall) begin
            dispatcher_lsu_inf.ctrl.register_write <= id_dispatcher_inf.ctrl.register_write;
            dispatcher_lsu_inf.ctrl.mem_store <= id_dispatcher_inf.ctrl.mem_store;
            dispatcher_lsu_inf.ctrl.mem_load <= id_dispatcher_inf.ctrl.mem_load;
            dispatcher_lsu_inf.ctrl.lsu_control <= id_dispatcher_inf.ctrl.lsu_control;
        end
    end

    always_ff @(posedge clk) begin
        dispatcher_lsu_inf.rd <= id_dispatcher_inf.rd;
        dispatcher_lsu_inf.rs1 <= rs1;
        dispatcher_lsu_inf.imm_ext <= id_dispatcher_inf.imm_ext;
        dispatcher_lsu_inf.write_data <= rs2;
    end

    // Propagate control signals to MUL
    always_ff @(posedge clk) begin
        if (flush)
            dispatcher_mul_inf.ctrl.instruction_valid <= `FALSE;
        else
            dispatcher_mul_inf.ctrl.instruction_valid <= decoded_instruction_valid & id_dispatcher_inf.ctrl.exe_pipe[`EXE_PIPE_ID_MUL];
    end

    always_ff @(posedge clk) begin
        if (flush) begin
            dispatcher_mul_inf.ctrl.mul_control <= MUL_OP_MUL;
        end else if (!stall) begin
            dispatcher_mul_inf.ctrl.mul_control <= id_dispatcher_inf.ctrl.mul_control;
        end
    end

    always_ff @(posedge clk) begin
        dispatcher_mul_inf.rd <= id_dispatcher_inf.rd;
        // No immediates; MUL operates only on registers.
        dispatcher_mul_inf.rs1 <= rs1;
        dispatcher_mul_inf.rs2 <= rs2;
    end

    // Propagate control signals to DIV
    always_ff @(posedge clk) begin
        if (flush)
            dispatcher_div_inf.ctrl.instruction_valid <= `FALSE;
        else if (!stall)
            dispatcher_div_inf.ctrl.instruction_valid <= decoded_instruction_valid & id_dispatcher_inf.ctrl.exe_pipe[`EXE_PIPE_ID_DIV];
    end

    always_ff @(posedge clk) begin
        if (flush) begin
            dispatcher_div_inf.ctrl.div_control <= DIV_OP_DIV;
        end else if (!stall) begin
            dispatcher_div_inf.ctrl.div_control <= id_dispatcher_inf.ctrl.div_control;
        end
    end

    always_ff @(posedge clk) begin
        dispatcher_div_inf.rd <= id_dispatcher_inf.rd;
        // No immediates; DIV operates only on registers
        dispatcher_div_inf.rs1 <= rs1;
        dispatcher_div_inf.rs2 <= rs2;
    end

    // Optional bypass path from WB
    assign fwd_rs1_wb = ENABLE_BYPASS_WB ? (wb_dispatcher_inf.wr_en && (wb_dispatcher_inf.rd == id_dispatcher_inf.a1)) : `FALSE;
    assign fwd_rs2_wb = ENABLE_BYPASS_WB ? (wb_dispatcher_inf.wr_en && (wb_dispatcher_inf.rd == id_dispatcher_inf.a2)) : `FALSE;
    assign fwd_rd_wb = ENABLE_BYPASS_WB ? (wb_dispatcher_inf.wr_en && (wb_dispatcher_inf.rd == id_dispatcher_inf.rd)) : `FALSE;

    // SB registers
    always_ff @(posedge clk) begin
        if (rst)
            sb_gpr_reg <= '0;
        else
            sb_gpr_reg <= (sb_gpr_reg & (~sb_wb_bits)) | (sb_rd_bits & {NUM_REGS{decoded_instruction_valid}});
    end

    // Set bit for used GPRs
    always_comb begin
        sb_deps_bits = '0;
        sb_deps_bits[id_dispatcher_inf.rd] = ~fwd_rd_wb;
        sb_deps_bits[id_dispatcher_inf.a1] = ~fwd_rs1_wb;
        sb_deps_bits[id_dispatcher_inf.a2] = ~fwd_rs2_wb;
    end

    // Set bit for used DST
    always_comb begin
        sb_rd_bits = '0;

        if (id_dispatcher_inf.ctrl.register_write)
            sb_rd_bits[id_dispatcher_inf.rd] = `TRUE;
    end

    // Clear pending bit after write-back
    always_comb begin
        sb_wb_bits = '0;

        if (wb_dispatcher_inf.wr_en)
            sb_wb_bits[wb_dispatcher_inf.rd] = `TRUE;
    end

    // Determine SB conflicts
    assign sb_conflict = (sb_gpr_reg & sb_deps_bits) != NUM_REGS'(0);

    always_ff @(posedge clk) begin
        if (rst)
            wb_active_mul_reg <= '0;
        else
            wb_active_mul_reg <= {wb_active_mul_reg[LATENCY_MUL_OP-2:0], (decoded_instruction_valid & (id_dispatcher_inf.ctrl.exe_pipe[`EXE_PIPE_ID_MUL]))};
    end

    // Determine conflict at WB
    always_comb begin
        wb_conflict = 1'b0;

        //TODO: Cover all concurrent EXE pipes!
        unique case (id_dispatcher_inf.ctrl.exe_pipe)
            EXE_PIPE_ALU: wb_conflict = wb_active_mul_reg[LATENCY_MUL_OP - LATENCY_ALU_OP];
            EXE_PIPE_LSU: wb_conflict = wb_active_mul_reg[LATENCY_MUL_OP - LATENCY_LSU_OP];
            default: ;
        endcase
    end

    // Stalls due to out-of-pipeline divider
    always_ff @(posedge clk) begin
        if (flush || div_done) // div_done has priority over stall
            div_stall_reg <= `FALSE;
        else if (!stall)
            div_stall_reg <= id_dispatcher_inf.ctrl.exe_pipe[`EXE_PIPE_ID_DIV];
    end

    // Stall upstream until all write-back and register conflicts are resolved.
    assign dispatcher_conflict = sb_conflict || wb_conflict;

    // Stall the pre-DIV stages until serial division operation is performed.
    assign div_stall = div_stall_reg;
endmodule