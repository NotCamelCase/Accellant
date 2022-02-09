`include "defines.svh"

module exe_alu
(
    input logic                 clk, rst,
    // From Core
    input logic                 stall,
    input logic                 flush,
    // To Core
    output logic                branch_taken,
    output logic[31:0]          branch_target,
    // From Dispatcher
    input dispatcher_alu_inf_t  dispatcher_alu_inf,
    // To WB
    output exe_wb_inf_t         alu_wb_inf
);
    logic[31:0] add_result, sub_result;
    logic[31:0] and_result, or_result, xor_result;
    logic[31:0] sll_result, srl_result;
    logic[31:0] sra_result;
    logic       lt_result, ltu_result;
    logic[31:0] lui_result;
    logic[31:0] auipc_result;

    logic[4:0]  shtamt;
    logic[31:0] src_a, src_b;
    logic[31:0] alu_result;

    // ALU -> WB signals
    always_ff @(posedge clk) begin
        if (flush) begin
            alu_wb_inf.instruction_valid <= `FALSE;
            alu_wb_inf.register_write <= `FALSE;
        end else if (!stall) begin
            alu_wb_inf.instruction_valid <= dispatcher_alu_inf.ctrl.instruction_valid;
            alu_wb_inf.register_write <= dispatcher_alu_inf.ctrl.register_write;
            alu_wb_inf.rd <= dispatcher_alu_inf.rd;
            alu_wb_inf.exe_result <= dispatcher_alu_inf.ctrl.result_src ? dispatcher_alu_inf.pc_inc : alu_result;
        end
    end

    assign src_a = dispatcher_alu_inf.rs1;
    assign src_b = dispatcher_alu_inf.rs2; // MUX for imm_ext by Dispatcher unit already

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
    
    //TODO: Convert to use src_b instead?
    assign lui_result = {dispatcher_alu_inf.imm_ext[31:12], 12'b0};
    assign auipc_result = dispatcher_alu_inf.pc + dispatcher_alu_inf.imm_ext;

    always_comb begin
        alu_result = 32'h0;

        unique case (dispatcher_alu_inf.ctrl.alu_control)
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
    assign branch_target = dispatcher_alu_inf.imm_ext + (dispatcher_alu_inf.ctrl.jalr ? src_a : dispatcher_alu_inf.pc);

    // Resolve branch/jump
    always_comb begin
        branch_taken = `FALSE;

        //TODO: Separate from bypassed ALU path to relax timing of pc_src!!!

        if (dispatcher_alu_inf.ctrl.jal || dispatcher_alu_inf.ctrl.jalr)
            branch_taken = `TRUE;
        else if (dispatcher_alu_inf.ctrl.branch) begin
            unique case (dispatcher_alu_inf.ctrl.branch_op)
                BRANCH_OP_BEQ:     branch_taken = ~(|sub_result);
                BRANCH_OP_BNE:     branch_taken = |sub_result;
                BRANCH_OP_BLT:     branch_taken = lt_result;
                BRANCH_OP_BLTU:    branch_taken = ltu_result;
                BRANCH_OP_BGE:     branch_taken = ~lt_result;
                default: branch_taken = ~ltu_result;
            endcase
        end
    end
endmodule