`include "defines.svh"

module exe_alu
(
    input logic             clk, rst,
    // To Core
    output logic            pc_src,
    output logic[31:0]      branch_target,
    // From Core
    input logic[1:0]        fwd_rs1, fwd_rs2,
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
    logic[31:0] branch_result;

    logic[4:0]  shtamt;
    logic[31:0] write_data;
    logic[31:0] src_a, src_b;
    logic[31:0] alu_result;

    // Propagate control signals to MEM
    always_ff @(posedge clk) begin
        if (rst) begin
            exe_mem_inf.ctrl.register_write <= 1'b0;
            exe_mem_inf.ctrl.result_src <= 2'b0;
            exe_mem_inf.ctrl.mem_store <= 1'b0;
            exe_mem_inf.ctrl.mem_load <= 1'b0;
        end else begin
            exe_mem_inf.ctrl.register_write <= id_exe_inf.ctrl.register_write;
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

    assign write_data = ((fwd_rs2 == 2'b10) ? mem_alu_result :
                        ((fwd_rs2 == 2'b01) ? wb_wr_data :
                        id_exe_inf.rs2));

    assign src_a = (fwd_rs1 == 2'b10) ? mem_alu_result :
                   ((fwd_rs1 == 2'b01) ? wb_wr_data :
                   id_exe_inf.rs1);

    assign src_b = id_exe_inf.ctrl.alu_src ? id_exe_inf.imm_ext : write_data;

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
            4'b0000: alu_result = add_result;
            4'b1000: alu_result = sub_result;
            4'b0001: alu_result = sll_result;
            4'b0010: alu_result = {31'b0, lt_result};
            4'b0011: alu_result = {31'b0, ltu_result};
            4'b0100: alu_result = xor_result;
            4'b0101: alu_result = srl_result;
            4'b1101: alu_result = sra_result;
            4'b0110: alu_result = or_result;
            4'b0111: alu_result = and_result;
            4'b1111: alu_result = lui_result;
            4'b1110: alu_result = auipc_result;
            default: ;
        endcase
    end


    // Resolve branch/jump
    always_comb begin
        pc_src = 1'b0;

        branch_result = src_a - src_b;
        
        //TODO: Remaining branch ops!!!

        if (id_exe_inf.ctrl.jal || id_exe_inf.ctrl.jalr)
            pc_src = 1'b1;
        else if (id_exe_inf.ctrl.branch)
            pc_src = ((id_exe_inf.ctrl.branch_op == 3'b0) && ~(|branch_result)) || ((id_exe_inf.ctrl.branch_op == 3'b1) && (|branch_result));

        branch_target = id_exe_inf.imm_ext + (id_exe_inf.ctrl.jalr ? src_a : id_exe_inf.pc);
        branch_target = {branch_target[31:1], 1'b0};
    end
endmodule