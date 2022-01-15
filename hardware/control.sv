`include "defines.svh"

module control
(
    input logic[6:0]    op,
    input logic[2:0]    funct3,
    input logic[6:0]    funct7,
    output wb_src_e     result_src,
    output logic        branch, jal, jalr,
    output logic        mem_store,
    output logic        mem_load,
    output alu_op_e     alu_control,
    output logic        alu_src,
    output imm_type_e   imm_src,
    output logic        register_write
);
    // Main decoder
    always_comb begin
        result_src = WB_SRC_ALU;
        mem_store = 1'b0;
        mem_load = 1'b0;
        alu_control = ALU_OP_ADD;
        alu_src = 1'b0;
        imm_src = IMM_TYPE_I;
        register_write = 1'b0;

        branch = 1'b0;
        jal = 1'b0;
        jalr = 1'b0;

        unique case (op)
            7'b0110011: begin // R-type
                alu_control = alu_op_e'({funct7[5], funct3});
                register_write = 1'b1;
            end

            7'b0000011: begin // Memory load operations
                result_src = WB_SRC_MEM_READ;
                mem_load = 1'b1;
                alu_src = 1'b1;
                register_write = 1'b1;

                //TODO: Byte/half-word instructions!
            end

            7'b0100011: begin // Memory store operations
                mem_store = 1'b1;
                alu_src = 1'b1;
                imm_src = IMM_TYPE_S;

                //TODO: Byte/half-word instructions!
            end

            7'b1100011: begin // Conditional branch operations
                imm_src = IMM_TYPE_B;

                branch = 1'b1;
            end

            7'b0010011: begin // I-type
                alu_control = alu_op_e'({funct7[5] & (|funct3), funct3});
                alu_src = 1'b1;
                imm_src = ((funct3 == 3'b001) || (funct3 == 3'b101)) ? IMM_TYPE_SH : IMM_TYPE_I;
                register_write = 1'b1;
            end

            7'b1100111: begin // JALR
                result_src = WB_SRC_PC_INC;
                alu_src = 1'b1;
                register_write = 1'b1;

                jalr = 1'b1;
            end

            7'b1101111: begin // J-type
                result_src = WB_SRC_PC_INC;
                imm_src = IMM_TYPE_J;
                register_write = 1'b1;

                jal = 1'b1;
            end

            7'b0110111: begin // LUI
                register_write = 1'b1;
                imm_src = IMM_TYPE_U;
                alu_src = 1'b1;
                alu_control = ALU_OP_LUI;
            end

            7'b0010111: begin // AUIPC
                register_write = 1'b1;
                imm_src = IMM_TYPE_U;
                alu_control = ALU_OP_AUIPC;
            end

            // 7'b0001111 -> FENCE
            // 7'b1110011 -> ECALL/EBREAK

            default: ; //TODO: Assert for undefined/un-implemented opcodes!!!
        endcase
    end
endmodule