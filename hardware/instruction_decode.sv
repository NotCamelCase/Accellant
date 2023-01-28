`include "defines.svh"

import defines::*;

module instruction_decode
(
    input logic         clk, rst,
    // WB -> IFT
    input logic         wb_do_branch,
    // IFD -> ID
    input logic         ifd_valid,
    input ifd_id_inf_t  ifd_id_inf,
    // ID -> IX
    output logic        id_valid,
    output id_ix_inf_t  id_ix_inf
);
    // Control signals
    logic                   register_write;
    logic[2:0]              funct3;
    logic[6:0]              funct7;
    logic                   result_src;
    logic                   mem_store;
    logic                   mem_load;
    logic                   icache_invalidate;
    logic                   branch, jal, jalr;
    branch_op_e             branch_op;
    alu_op_e                alu_control;
    mul_op_e                mul_control;
    div_op_e                div_control;
    logic                   alu_src;
    imm_type_e              imm_src;
    logic[2:0]              lsu_control;

    logic[REG_WIDTH-1:0]    a1, a2, rd; // Decoded operands
    exe_pipe_e              exe_pipe;   // Which execution unit instruction will be dispatched to

    // Immediates
    logic[4:0]              imm_ext_shamt;
    logic[11:0]             imm_ext_i;
    logic[11:0]             imm_ext_s;
    logic[11:0]             imm_ext_b;
    logic[19:0]             imm_ext_j;
    logic[19:0]             imm_ext_u;
    logic[31:0]             imm_ext;

    // Main decoder
    always_comb begin
        funct3 = ifd_id_inf.instr[14:12];
        funct7 = ifd_id_inf.instr[31:25];

        result_src = 1'b0;

        mem_store = 1'b0;
        mem_load = 1'b0;

        icache_invalidate = 1'b0;

        alu_control = ALU_OP_ADD;
        mul_control = MUL_OP_MUL;
        div_control = DIV_OP_DIV;
        lsu_control = funct3;

        alu_src = 1'b0;
        imm_src = IMM_TYPE_I;

        register_write = 1'b0;

        branch = 1'b0;
        jal = 1'b0;
        jalr = 1'b0;
        branch_op = branch_op_e'(ifd_id_inf.instr[14:12]);

        exe_pipe = EXE_PIPE_INVALID;

        a1 = ifd_id_inf.instr[19:15];
        a2 = ifd_id_inf.instr[24:20];
        rd = ifd_id_inf.instr[11:7];

        unique case (ifd_id_inf.instr[6:0])
            INSTR_OPCODE_ALU_MUL_DIV_R: begin
                register_write = 1'b1;
                alu_control = alu_op_e'({funct7[5], funct3});
                mul_control = mul_op_e'(funct3[1:0]);
                div_control = div_op_e'(funct3[1:0]);

                exe_pipe[EXE_PIPE_ID_ALU] = ~funct7[0]; // ALU pipe
                exe_pipe[EXE_PIPE_ID_MUL] = funct7[0] & (~funct3[2]); // MUL pipe
                exe_pipe[EXE_PIPE_ID_DIV] = funct7[0] & funct3[2]; // DIV pipe
            end

            INSTR_OPCODE_LSU_LOAD: begin
                mem_load = 1'b1;
                alu_src = 1'b1;
                register_write = 1'b1;
                a2 = '0;
                exe_pipe[EXE_PIPE_ID_LSU] = 1'b1;
            end

            INSTR_OPCODE_LSU_STORE: begin
                mem_store = 1'b1;
                alu_src = 1'b1;
                imm_src = IMM_TYPE_S;
                exe_pipe[EXE_PIPE_ID_LSU] = 1'b1;
                rd = '0;
            end

            INSTR_OPCODE_ALU_BRANCH: begin
                imm_src = IMM_TYPE_B;
                branch = 1'b1;
                exe_pipe[EXE_PIPE_ID_ALU] = 1'b1;
                rd = '0;
            end

            INSTR_OPCODE_ALU_I: begin
                alu_control = alu_op_e'({(funct3 == 3'b101), funct3});
                alu_src = 1'b1;
                imm_src = ((funct3 == 3'b001) || (funct3 == 3'b101)) ? IMM_TYPE_SH : IMM_TYPE_I;
                register_write = 1'b1;
                a2 = '0;
                exe_pipe[EXE_PIPE_ID_ALU] = 1'b1;
            end

            INSTR_OPCODE_ALU_JALR: begin
                result_src = 1'b1;
                alu_src = 1'b1;
                register_write = 1'b1;
                a2 = '0;
                //imm_src = IMM_TYPE_I;
                jalr = 1'b1;
                exe_pipe[EXE_PIPE_ID_ALU] = 1'b1;
            end

            INSTR_OPCODE_ALU_JAL: begin
                result_src = 1'b1;
                imm_src = IMM_TYPE_J;
                register_write = 1'b1;
                a1 = '0;
                a2 = '0;

                jal = 1'b1;
                exe_pipe[EXE_PIPE_ID_ALU] = 1'b1;
            end

            INSTR_OPCODE_ALU_LUI: begin
                register_write = 1'b1;
                a1 = '0;
                a2 = '0;
                imm_src = IMM_TYPE_U;
                //alu_src = 1'b1;
                alu_control = ALU_OP_LUI;
                exe_pipe[EXE_PIPE_ID_ALU] = 1'b1;
            end

            INSTR_OPCODE_ALU_AUIPC: begin
                register_write = 1'b1;
                a1 = '0;
                a2 = '0;
                imm_src = IMM_TYPE_U;
                //alu_src = 1'b1;
                alu_control = ALU_OP_AUIPC;
                exe_pipe[EXE_PIPE_ID_ALU] = 1'b1;
            end

            INSTR_OPCODE_FENCE: begin
                // Route I$ invalidation to ALU
                icache_invalidate = (funct3 == 3'b001); // fence.i
                a1 = '0;
                a2 = '0;
                rd = '0;
                exe_pipe[EXE_PIPE_ID_ALU] = 1'b1;
            end

            //TODO: FPU ops
            //TODO: CSR ops

            default: ; //TODO: Assert for undefined/un-implemented opcodes!!!
        endcase

        // Drop writes to x0
        register_write &= (|rd);
    end

    // Immediate types
    assign imm_ext_i = ifd_id_inf.instr[31:20];
    assign imm_ext_s = {ifd_id_inf.instr[31:25], ifd_id_inf.instr[11:7]};
    assign imm_ext_b = {ifd_id_inf.instr[7], ifd_id_inf.instr[30:25], ifd_id_inf.instr[11:8], 1'b0};
    assign imm_ext_j = {ifd_id_inf.instr[19:12], ifd_id_inf.instr[20], ifd_id_inf.instr[30:21], 1'b0};
    assign imm_ext_shamt = ifd_id_inf.instr[24:20];
    assign imm_ext_u = ifd_id_inf.instr[31:12];

    // Decode immediates based on instruction type
    always_comb begin
        unique case (imm_src)
            IMM_TYPE_I: imm_ext = {{20{ifd_id_inf.instr[31]}}, imm_ext_i};
            IMM_TYPE_S: imm_ext = {{20{ifd_id_inf.instr[31]}}, imm_ext_s};
            IMM_TYPE_B: imm_ext = {{20{ifd_id_inf.instr[31]}}, imm_ext_b};
            IMM_TYPE_J: imm_ext = {{12{ifd_id_inf.instr[31]}}, imm_ext_j};
            IMM_TYPE_SH: imm_ext = {27'b0, imm_ext_shamt};
            default: imm_ext = {imm_ext_u, 12'b0}; // IMM_TYPE_U
        endcase
    end

    always_ff @(posedge clk) begin
        if (rst || wb_do_branch)
            id_valid <= 1'b0;
        else
            id_valid <= ifd_valid;
    end

    // Outputs to IX
    always_ff @(posedge clk) begin
        id_ix_inf.a1 <= a1;
        id_ix_inf.a2 <= a2;
        id_ix_inf.rd <= rd;
        id_ix_inf.imm_ext <= imm_ext;
        id_ix_inf.pc <= ifd_id_inf.pc;
        id_ix_inf.pc_inc <= ifd_id_inf.pc_inc;
        id_ix_inf.register_write <= register_write;
        id_ix_inf.branch <= branch;
        id_ix_inf.jal <= jal;
        id_ix_inf.jalr <= jalr;
        id_ix_inf.branch_op <= branch_op;
        id_ix_inf.result_src <= result_src;
        id_ix_inf.mem_store <= mem_store;
        id_ix_inf.mem_load <= mem_load;
        id_ix_inf.icache_invalidate <= icache_invalidate;
        id_ix_inf.alu_control <= alu_control;
        id_ix_inf.mul_control <= mul_control;
        id_ix_inf.div_control <= div_control;
        id_ix_inf.lsu_control <= lsu_control;
        id_ix_inf.alu_src <= alu_src;
        id_ix_inf.exe_pipe <= exe_pipe;
    end
endmodule