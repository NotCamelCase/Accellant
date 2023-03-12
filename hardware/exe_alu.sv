`include "defines.svh"

import defines::*;

module exe_alu
(
    input logic         clk, rst,
    input logic         wb_do_branch,
    // IX -> ALU
    input logic         ix_alu_valid,
    input ix_alu_inf_t  ix_alu_inf,
    // ALU -> WB
    output logic        alu_valid,
    output alu_wb_inf_t alu_wb_inf
);
    logic[31:0]     add_result, sub_result;
    logic[31:0]     and_result, or_result, xor_result;
    logic[31:0]     sll_result, srl_result;
    logic[31:0]     sra_result;
    logic           lt_result, ltu_result;
    logic[31:0]     lui_result;
    logic[31:0]     auipc_result;

    logic[4:0]      shtamt;
    logic[31:0]     src_a, src_b;
    logic[31:0]     alu_result;

    logic           branch_taken;
    logic[31:0]     branch_target;

    assign src_a = ix_alu_inf.rs1;
    assign src_b = ix_alu_inf.rs2; // MUX for imm_ext by IX already

    // ADD operation
    assign add_result = src_a + src_b;

    // SUB operation
    assign sub_result = src_a - src_b;

    // AND operation
    assign and_result = src_a & src_b;

    // OR operation
    assign or_result = src_a | src_b;

    // XOR operation
    assign xor_result = src_a ^ src_b;

    assign shtamt = src_b[4:0];

    // Shift operations
    assign sll_result = src_a << shtamt;
    assign srl_result = src_a >> shtamt;
    assign sra_result = src_a >>> shtamt;

    // LESS_THAN operation
    assign lt_result = $signed(src_a) < $signed(src_b); // signed
    assign ltu_result = src_a < src_b; // unsigned

    // LUI and AUIPC operations
    assign lui_result = {ix_alu_inf.imm_ext[31:12], 12'b0};
    assign auipc_result = ix_alu_inf.pc + ix_alu_inf.imm_ext;

    always_comb begin
        unique case (ix_alu_inf.alu_control)
            ALU_OP_ADD: alu_result = add_result;
            ALU_OP_SUB: alu_result = sub_result;
            ALU_OP_SLL: alu_result = sll_result;
            ALU_OP_LT:  alu_result = {31'b0, lt_result};
            ALU_OP_LTU: alu_result = {31'b0, ltu_result};
            ALU_OP_XOR: alu_result = xor_result;
            ALU_OP_SRL: alu_result = srl_result;
            ALU_OP_SRA: alu_result = sra_result;
            ALU_OP_OR:  alu_result = or_result;
            ALU_OP_AND: alu_result = and_result;
            ALU_OP_LUI: alu_result = lui_result;
            default:    alu_result = auipc_result;
        endcase
    end

    // Calculate branch target
    assign branch_target = ix_alu_inf.pc_base + ix_alu_inf.imm_ext;

    // Resolve branch/jump
    always_comb begin
        branch_taken = 1'b0;

        if (ix_alu_inf.jump) begin
            // On unconditional branches, BTP can be applied if branch was taken and branch target is up-to-date
            branch_taken = !(ix_alu_inf.btp_info.branch_taken && (ix_alu_inf.btp_info.branch_target == branch_target));
        end else if (ix_alu_inf.branch) begin
            unique case (ix_alu_inf.branch_op)
                BRANCH_OP_BEQ:  branch_taken = ~(|sub_result);
                BRANCH_OP_BNE:  branch_taken = |sub_result;
                BRANCH_OP_BLT:  branch_taken = lt_result;
                BRANCH_OP_BLTU: branch_taken = ltu_result;
                BRANCH_OP_BGE:  branch_taken = ~lt_result;
                default: branch_taken = ~ltu_result; // BGEU
            endcase

            // On conditional branches, BTP can be applied if either branch was taken and prediction was valid
            // or branch was NOT taken and prediction was invalid
            branch_taken = (branch_taken ^ ix_alu_inf.btp_info.branch_taken);
        end
    end

    always_ff @(posedge clk) alu_valid <= ix_alu_valid && !wb_do_branch;

    // Outputs to WB
    always_ff @(posedge clk) begin
        alu_wb_inf.do_branch <= (ix_alu_inf.icache_invalidate || branch_taken) && (ix_alu_valid && !wb_do_branch);
        alu_wb_inf.branch_target <= (ix_alu_inf.icache_invalidate || (ix_alu_inf.branch && ix_alu_inf.btp_info.branch_taken)) ? ix_alu_inf.pc_inc : branch_target; // If I$ invalidation request (fence.i), branch off to PC+4 or else the computed branch target, if mis-predicted.
        alu_wb_inf.control_flow_pc <= {ix_alu_inf.pc[31:2], 1'b0, ix_alu_inf.jump || ~ix_alu_inf.btp_info.branch_taken}; // PC of control-flow instruction used for branch prediction
        alu_wb_inf.icache_invalidate <= ix_alu_inf.icache_invalidate;
        alu_wb_inf.register_write <= ix_alu_inf.register_write;
        alu_wb_inf.rd <= ix_alu_inf.rd;
        alu_wb_inf.exe_result <= ix_alu_inf.result_src ? ix_alu_inf.pc_inc : alu_result;
    end
endmodule