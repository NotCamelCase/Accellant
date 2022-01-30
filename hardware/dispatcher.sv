`include "defines.svh"

module dispatcher
(
    input logic                 clk, rst,
    // From Core
    input logic                 stall,
    input logic                 flush,
    // To Core
    output logic                dispatcher_conflict,
    // From ID
    input id_dispatcher_inf_t   id_dispatcher_inf,
    // From WB
    input wb_dispatcher_inf_t   wb_dispatcher_inf,
    // To ALU
    output dispatcher_alu_inf_t dispatcher_alu_inf,
    // To LSU
    output dispatcher_lsu_inf_t dispatcher_lsu_inf
);
    //TODO: Re-org
    localparam  SP      = 32'h300;
    localparam  GP      = 32'h3ff;

    logic               decoded_instruction_valid;

    // Architectural register file
    logic[31:0]         reg_file[NUM_REGS-1:0]; //TODO: 1) Unify read/write 2) Extract module

    // Scoreboard
    logic               sb_conflict;
    logic[NUM_REGS-1:0] sb_gpr_reg;
    logic[NUM_REGS-1:0] sb_deps_bits, sb_rd_bits, sb_wb_bits;

    //TODO: Write-back conflict mitigation for EXE pipes of inequal lengths

    // Initialize x0 and SP/GP for simulation
    initial begin
        reg_file[0] = 0;
        reg_file[2] = SP;
        reg_file[3] = GP;
    end

    // Read register file synchronously
    always_ff @(posedge clk) begin
        dispatcher_alu_inf.rs1 <= reg_file[id_dispatcher_inf.a1];

        // Bake imm_ext into rs2 for simple ALU operations
        // imm_ext in ALU is still needed for:
            // 1) branch/jump
            // 2) LUI & AUIPC instructions
        dispatcher_alu_inf.rs2 <= id_dispatcher_inf.ctrl.alu_src ? id_dispatcher_inf.imm_ext : reg_file[id_dispatcher_inf.a2];
    end

    // Write-back to register file
    always_ff @(posedge clk) begin
        if (wb_dispatcher_inf.wr_en)
            reg_file[wb_dispatcher_inf.rd] <= wb_dispatcher_inf.wr_data;
    end

    // Propagate control signals to ALU
    always_ff @(posedge clk) begin
        if (flush) begin
            dispatcher_alu_inf.ctrl.instruction_valid <= `FALSE;
            dispatcher_alu_inf.ctrl.register_write <= `FALSE;
            dispatcher_alu_inf.ctrl.branch <= `FALSE;
            dispatcher_alu_inf.ctrl.jal <= `FALSE;
            dispatcher_alu_inf.ctrl.jalr <= `FALSE;
            dispatcher_alu_inf.ctrl.branch_op <= BRANCH_OP_BEQ;
            dispatcher_alu_inf.ctrl.result_src <= `FALSE;
            dispatcher_alu_inf.ctrl.mem_store <= `FALSE;
            dispatcher_alu_inf.ctrl.mem_load <= `FALSE;
            dispatcher_alu_inf.ctrl.alu_control <= ALU_OP_ADD;
        end else if (!stall) begin
            dispatcher_alu_inf.ctrl.instruction_valid <= id_dispatcher_inf.ctrl.exe_pipe[EXE_PIPE_ALU_BIT];
            dispatcher_alu_inf.ctrl.register_write <= id_dispatcher_inf.ctrl.register_write;
            dispatcher_alu_inf.ctrl.branch <= id_dispatcher_inf.ctrl.branch;
            dispatcher_alu_inf.ctrl.jal <= id_dispatcher_inf.ctrl.jal;
            dispatcher_alu_inf.ctrl.jalr <= id_dispatcher_inf.ctrl.jalr;
            dispatcher_alu_inf.ctrl.branch_op <= id_dispatcher_inf.ctrl.branch_op;
            dispatcher_alu_inf.ctrl.result_src <= id_dispatcher_inf.ctrl.result_src;
            dispatcher_alu_inf.ctrl.mem_store <= id_dispatcher_inf.ctrl.mem_store;
            dispatcher_alu_inf.ctrl.mem_load <= id_dispatcher_inf.ctrl.mem_load;
            dispatcher_alu_inf.ctrl.alu_control <= id_dispatcher_inf.ctrl.alu_control;
        end
    end

    always_ff @(posedge clk) begin
        dispatcher_alu_inf.rd <= id_dispatcher_inf.rd;
        dispatcher_alu_inf.pc <= id_dispatcher_inf.pc;
        dispatcher_alu_inf.pc_inc <= id_dispatcher_inf.pc_inc;
        dispatcher_alu_inf.imm_ext <= id_dispatcher_inf.imm_ext;
    end

    // Propagate control signals to MEM
    always_ff @(posedge clk) begin
        if (flush) begin
            dispatcher_lsu_inf.ctrl.instruction_valid <= `FALSE;
            dispatcher_lsu_inf.ctrl.register_write <= `FALSE;
            dispatcher_lsu_inf.ctrl.mem_store <= `FALSE;
            dispatcher_lsu_inf.ctrl.mem_load <= `FALSE;
        end else if (!stall) begin
            dispatcher_lsu_inf.ctrl.instruction_valid <= id_dispatcher_inf.ctrl.exe_pipe[EXE_PIPE_LSU_BIT];
            dispatcher_lsu_inf.ctrl.register_write <= id_dispatcher_inf.ctrl.register_write;
            dispatcher_lsu_inf.ctrl.mem_store <= id_dispatcher_inf.ctrl.mem_store;
            dispatcher_lsu_inf.ctrl.mem_load <= id_dispatcher_inf.ctrl.mem_load;
        end
    end

    always_ff @(posedge clk) begin
        dispatcher_lsu_inf.rd <= id_dispatcher_inf.rd;
        dispatcher_lsu_inf.rs1 <= reg_file[id_dispatcher_inf.a1];
        dispatcher_lsu_inf.imm_ext <= id_dispatcher_inf.imm_ext;
        dispatcher_lsu_inf.write_data <= reg_file[id_dispatcher_inf.a2];
    end

    // Decoded instruction is valid if no stall or flush occurs
    assign decoded_instruction_valid = ~(stall | flush); //TODO: Needs enhancement?

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
        sb_deps_bits[id_dispatcher_inf.rd] = `TRUE;
        sb_deps_bits[id_dispatcher_inf.a1] = `TRUE;
        sb_deps_bits[id_dispatcher_inf.a2] = `TRUE;
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

    assign sb_conflict = (sb_gpr_reg & sb_deps_bits) != NUM_REGS'(0);

    // Stall upstream until all write-back and register conflicts are resolved.
    assign dispatcher_conflict = sb_conflict; //TODO: Conflict at write-back stage!!!
endmodule