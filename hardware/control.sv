module control
(
    input logic[6:0]    op,
    input logic[2:0]    funct3,
    input logic[6:0]    funct7,
    output logic[1:0]   result_src,
    output logic        branch, jal, jalr,
    output logic        mem_store,
    output logic        mem_load,
    output logic[3:0]   alu_control,
    output logic        alu_src,
    output logic[2:0]   imm_src,
    output logic        register_write
);
    // Main decoder
    always_comb begin
        result_src = 2'b0;
        mem_store = 1'b0;
        mem_load = 1'b0;
        alu_control = 4'b0;
        alu_src = 1'b0;
        imm_src = 3'b0;
        register_write = 1'b0;

        branch = 1'b0;
        jal = 1'b0;
        jalr = 1'b0;

        unique case (op)
            7'b0110011: begin // R-type
                alu_control = {funct7[5], funct3};
                register_write = 1'b1;
            end

            7'b0000011: begin // lw
                result_src = 2'b01;
                mem_load = 1'b1;
                alu_control = 4'b0000;
                alu_src = 1'b1;
                register_write = 1'b1;
            end

            7'b0100011: begin // sw
                mem_store = 1'b1;
                alu_control = 4'b0000;
                alu_src = 1'b1;
                imm_src = 3'b001;
            end

            7'b1100011: begin // beq/bne
                imm_src = 3'b010;

                branch = 1'b1;
            end

            7'b0010011: begin // I-type
                alu_control = {funct7[5] & (|funct3), funct3};
                alu_src = 1'b1;
                imm_src = ((funct3 == 3'b001) || (funct3 == 3'b101)) ? 3'b100 : 3'b000;
                register_write = 1'b1;
            end

            7'b1100111: begin // I-type JALR
                result_src = 2'b10;
                alu_src = 1'b1;
                register_write = 1'b1;

                jalr = 1'b1;
            end

            7'b1101111: begin // J-type
                result_src = 2'b10;
                alu_src = 1'bx;
                imm_src = 3'b011;
                register_write = 1'b1;

                jal = 1'b1;
            end

            7'b0110111: begin // LUI
                register_write = 1'b1;
                imm_src = 3'b101;
                alu_src = 1'b1;
                alu_control = 4'b1111;
            end

            7'b0010111: begin // AUIPC
                register_write = 1'b1;
                imm_src = 3'b101;
                alu_control = 4'b1110;
            end

            default: ; //TODO: Assert for undefined/un-implemented opcodes!!!
        endcase
    end
endmodule