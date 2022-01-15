`include "defines.svh"

module exe_alu
(
    input logic             clk, rst,
    // From Core
    input logic             flush_mem,
    input bypass_src_e      fwd_rs1, fwd_rs2,
    // From ID 
    input id_exe_inf_t      id_exe_inf,
    // To MEM
    output exe_mem_inf_t    exe_mem_inf,
    // From MEM
    input logic[31:0]       mem_alu_result,
    // From WB
    input logic[31:0]       wb_wr_data
);
    logic[31:0] add_result, sub_result;
    logic[31:0] and_result, or_result, xor_result;
    logic[31:0] sll_result, srl_result;
    logic[31:0] sra_result;
    logic       lt_result, ltu_result;
    logic[31:0] lui_result;
    logic[31:0] auipc_result;

    logic       branch_taken;
    logic[4:0]  shtamt;
    logic[31:0] write_data;
    logic[31:0] src_a, src_b;
    logic[31:0] alu_result;

    // Propagate control signals to MEM
    always_ff @(posedge clk) begin
        if (rst || flush_mem) begin
            exe_mem_inf.ctrl.register_write <= 1'b0;
            exe_mem_inf.ctrl.branch_taken <= 1'b0;
            exe_mem_inf.ctrl.result_src <= WB_SRC_ALU;
            exe_mem_inf.ctrl.mem_store <= 1'b0;
            exe_mem_inf.ctrl.mem_load <= 1'b0;
        end else begin
            exe_mem_inf.ctrl.register_write <= id_exe_inf.ctrl.register_write;
            exe_mem_inf.ctrl.branch_taken <= branch_taken;
            exe_mem_inf.ctrl.result_src <= id_exe_inf.ctrl.result_src;
            exe_mem_inf.ctrl.mem_store <= id_exe_inf.ctrl.mem_store;
            exe_mem_inf.ctrl.mem_load <= id_exe_inf.ctrl.mem_load;
        end
    end

    always_ff @(posedge clk) begin
        exe_mem_inf.alu_result <= alu_result;
        exe_mem_inf.write_data <= write_data;
        exe_mem_inf.rd <= id_exe_inf.rd;
        exe_mem_inf.pc_inc <= id_exe_inf.pc_inc;
    end

    // MUX forwarded data or register data for RS1/RS2
    assign write_data = ({32{fwd_rs2 == BYPASS_MEMORY}} & mem_alu_result) |
                        ({32{fwd_rs2 == BYPASS_WRITEBACK}} & wb_wr_data) |
                        ({32{fwd_rs2 == BYPASS_REG_FILE}} & id_exe_inf.rs2);

    assign src_a = ({32{fwd_rs1 == BYPASS_MEMORY}} & mem_alu_result) |
                   ({32{fwd_rs1 == BYPASS_WRITEBACK}} & wb_wr_data) |
                   ({32{fwd_rs1 == BYPASS_REG_FILE}} & id_exe_inf.rs1);

    assign src_b = ({32{id_exe_inf.ctrl.alu_src}} & id_exe_inf.imm_ext) |
                   ({32{~id_exe_inf.ctrl.alu_src}} & write_data);

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
    
    assign lui_result = {id_exe_inf.imm_ext[31:12], 12'b0};
    assign auipc_result = id_exe_inf.pc + id_exe_inf.imm_ext;

    always_comb begin
        alu_result = 32'h0;

        unique case (id_exe_inf.ctrl.alu_control)
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

    // Register branch target
    always_ff @(posedge clk) begin
        exe_mem_inf.branch_target <= id_exe_inf.imm_ext + (id_exe_inf.ctrl.jalr ? src_a : id_exe_inf.pc);
    end

    // Resolve branch/jump
    always_comb begin
        branch_taken = 1'b0;

        if (id_exe_inf.ctrl.jal || id_exe_inf.ctrl.jalr)
            branch_taken = 1'b1;
        else if (id_exe_inf.ctrl.branch) begin
            unique case (id_exe_inf.ctrl.branch_op)
                BEQ:     branch_taken = ~(|sub_result);
                BNE:     branch_taken = |sub_result;
                BLT:     branch_taken = lt_result;
                BLTU:    branch_taken = ltu_result;
                BGE:     branch_taken = ~lt_result;
                default: branch_taken = ~ltu_result;
            endcase
        end
    end
endmodule