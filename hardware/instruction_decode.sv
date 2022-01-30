`include "defines.svh"

module instruction_decode
(
    input logic                 clk, rst,
    // From Core
    input logic                 stall,
    input logic                 flush,
    // From IF  
    input if_id_inf_t           if_id_inf,
    // To Dispatcher
    output id_dispatcher_inf_t  id_dispatcher_inf
);
    // Control signals
    logic                       register_write;
    logic[2:0]                  funct3;
    logic[6:0]                  funct7;
    logic                       result_src;
    logic                       mem_store;
    logic                       mem_load;
    logic                       branch, jal, jalr;
    branch_op_e                 branch_op;
    alu_op_e                    alu_control;
    logic                       alu_src;
    imm_type_e                  imm_src;

    logic[REG_WIDTH-1:0]        a1, a2, rd; // Decoded operands
    logic[NUM_EXE_PIPES-1:0]    exe_pipe; // Which execution unit instruction will be dispatched to

    // Immediates
    logic[4:0]                  imm_ext_shamt;
    logic[11:0]                 imm_ext_i;
    logic[11:0]                 imm_ext_s;
    logic[11:0]                 imm_ext_b;
    logic[19:0]                 imm_ext_j;
    logic[19:0]                 imm_ext_u;
    logic[31:0]                 imm_ext;

    // Main decoder
    always_comb begin
        result_src = `FALSE;
        mem_store = `FALSE;
        mem_load = `FALSE;
        alu_control = ALU_OP_ADD;
        alu_src = `FALSE;
        imm_src = IMM_TYPE_I;
        register_write = `FALSE;
        funct3 = if_id_inf.instr[14:12];
        funct7 = if_id_inf.instr[31:25];

        branch = `FALSE;
        jal = `FALSE;
        jalr = `FALSE;
        branch_op = branch_op_e'(if_id_inf.instr[14:12]);

        exe_pipe = '0;

        a1 = if_id_inf.instr[19:15];
        a2 = if_id_inf.instr[24:20];
        rd = if_id_inf.instr[11:7];

        unique case (if_id_inf.instr[6:0])
            INSTR_OPCODE_ALU_R: begin
                alu_control = alu_op_e'({funct7[5], funct3});
                register_write = `TRUE;

                exe_pipe[EXE_PIPE_ALU_BIT] = `TRUE;
            end

            INSTR_OPCODE_LSU_LOAD: begin
                mem_load = `TRUE;
                alu_src = `TRUE;
                register_write = `TRUE;
                a2 = '0;
                exe_pipe[EXE_PIPE_LSU_BIT] = `TRUE;
                //TODO: Byte/half-word instructions!
            end

            INSTR_OPCODE_LSU_STORE: begin
                mem_store = `TRUE;
                alu_src = `TRUE;
                imm_src = IMM_TYPE_S;
                exe_pipe[EXE_PIPE_LSU_BIT] = `TRUE;
                rd = '0;
                //TODO: Byte/half-word instructions!
            end

            INSTR_OPCODE_ALU_BRANCH: begin
                imm_src = IMM_TYPE_B;
                branch = `TRUE;
                exe_pipe[EXE_PIPE_ALU_BIT] = `TRUE;
                rd = '0;
            end

            INSTR_OPCODE_ALU_I: begin
                alu_control = alu_op_e'({funct7[5] & (|funct3), funct3});
                alu_src = `TRUE;
                imm_src = ((funct3 == 3'b001) || (funct3 == 3'b101)) ? IMM_TYPE_SH : IMM_TYPE_I;
                register_write = `TRUE;
                a2 = '0;
                exe_pipe[EXE_PIPE_ALU_BIT] = `TRUE;
            end

            INSTR_OPCODE_ALU_JALR: begin
                result_src = `TRUE;
                alu_src = `TRUE;
                register_write = `TRUE;
                a2 = '0;
                //imm_src = IMM_TYPE_I;
                jalr = `TRUE;
                exe_pipe[EXE_PIPE_ALU_BIT] = `TRUE;
            end

            INSTR_OPCODE_ALU_JAL: begin
                result_src = `TRUE;
                imm_src = IMM_TYPE_J;
                register_write = `TRUE;
                a1 = '0;
                a2 = '0;

                jal = `TRUE;
                exe_pipe[EXE_PIPE_ALU_BIT] = `TRUE;
            end

            INSTR_OPCODE_ALU_LUI: begin
                register_write = `TRUE;
                a1 = '0;
                a2 = '0;
                imm_src = IMM_TYPE_U;
                //alu_src = `TRUE;
                alu_control = ALU_OP_LUI;
                exe_pipe[EXE_PIPE_ALU_BIT] = `TRUE;
            end

            INSTR_OPCODE_ALU_AUIPC: begin
                register_write = `TRUE;
                a1 = '0;
                a2 = '0;
                imm_src = IMM_TYPE_U;
                //alu_src = `TRUE;
                alu_control = ALU_OP_AUIPC;
                exe_pipe[EXE_PIPE_ALU_BIT] = `TRUE;
            end

            default: ; //TODO: Assert for undefined/un-implemented opcodes!!!
        endcase

        // Drop writes to x0
        register_write &= (|rd);
    end

    // Propagate control signals to DISPATCHER
    always_ff @(posedge clk) begin
        if (flush) begin
            id_dispatcher_inf.ctrl.register_write <= `FALSE;
            id_dispatcher_inf.ctrl.branch <= `FALSE;
            id_dispatcher_inf.ctrl.jal <= `FALSE;
            id_dispatcher_inf.ctrl.jalr <= `FALSE;
            id_dispatcher_inf.ctrl.branch_op <= BRANCH_OP_BEQ;
            id_dispatcher_inf.ctrl.result_src <= `FALSE;
            id_dispatcher_inf.ctrl.mem_store <= `FALSE;
            id_dispatcher_inf.ctrl.mem_load <= `FALSE;
            id_dispatcher_inf.ctrl.alu_control <= ALU_OP_ADD;
            id_dispatcher_inf.ctrl.alu_src <= `FALSE;
            id_dispatcher_inf.ctrl.exe_pipe <= '0;
        end else if (!stall) begin
            id_dispatcher_inf.ctrl.register_write <= register_write;
            id_dispatcher_inf.ctrl.branch <= branch;
            id_dispatcher_inf.ctrl.jal <= jal;
            id_dispatcher_inf.ctrl.jalr <= jalr;
            id_dispatcher_inf.ctrl.branch_op <= branch_op;
            id_dispatcher_inf.ctrl.result_src <= result_src;
            id_dispatcher_inf.ctrl.mem_store <= mem_store;
            id_dispatcher_inf.ctrl.mem_load <= mem_load;
            id_dispatcher_inf.ctrl.alu_control <= alu_control;
            id_dispatcher_inf.ctrl.alu_src <= alu_src;
            id_dispatcher_inf.ctrl.exe_pipe <= exe_pipe;
        end
    end

    // Immediate types
    assign imm_ext_i = if_id_inf.instr[31:20];
    assign imm_ext_s = {if_id_inf.instr[31:25], if_id_inf.instr[11:7]};
    assign imm_ext_b = {if_id_inf.instr[7], if_id_inf.instr[30:25], if_id_inf.instr[11:8], `FALSE};
    assign imm_ext_j = {if_id_inf.instr[19:12], if_id_inf.instr[20], if_id_inf.instr[30:21], `FALSE};
    assign imm_ext_shamt = if_id_inf.instr[24:20];
    assign imm_ext_u = if_id_inf.instr[31:12];

    // Decode immediates based on instruction type
    always_comb begin
        imm_ext = 32'h0;

        unique case (imm_src)
            IMM_TYPE_I: imm_ext = {{20{if_id_inf.instr[31]}}, imm_ext_i};
            IMM_TYPE_S: imm_ext = {{20{if_id_inf.instr[31]}}, imm_ext_s};
            IMM_TYPE_B: imm_ext = {{20{if_id_inf.instr[31]}}, imm_ext_b};
            IMM_TYPE_J: imm_ext = {{12{if_id_inf.instr[31]}}, imm_ext_j};
            IMM_TYPE_SH: imm_ext = {27'b0, imm_ext_shamt};
            default: imm_ext = {imm_ext_u, 12'b0}; // IMM_TYPE_U
        endcase
    end

    always_ff @(posedge clk) begin
        if (flush) begin
            id_dispatcher_inf.a1 <= '0;
            id_dispatcher_inf.a2 <= '0;
            id_dispatcher_inf.rd <= '0;
            id_dispatcher_inf.imm_ext <= '0;
        end else if (!stall) begin
            id_dispatcher_inf.a1 <= a1;
            id_dispatcher_inf.a2 <= a2;
            id_dispatcher_inf.rd <= rd;
            id_dispatcher_inf.imm_ext <= imm_ext;
            id_dispatcher_inf.pc <= if_id_inf.pc;
            id_dispatcher_inf.pc_inc <= if_id_inf.pc_inc;
        end
    end
endmodule