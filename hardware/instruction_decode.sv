`include "defines.svh"

module instruction_decode
(
    input logic         clk, rst,
    //To Core
    output logic        pc_src, do_branch,
    output logic[31:0]  branch_target,
    output logic[4:0]   rs1_d, rs2_d,
    // From Core
    input logic         flush_exe,
    input logic         fwd_branch_rs1, fwd_branch_rs2,
    // From IF  
    input if_id_inf_t   if_id_inf,
    // From EXE
    input logic[31:0]   exe_alu_result,
    // To EXE
    output id_exe_inf_t id_exe_inf,
    // From WB
    input wb_id_inf_t   wb_id_inf
);
    localparam  SP      = 32'h300;
    localparam  GP      = 32'h300;

    localparam  XLEN    = 32;

    // Scalar ARF
    logic[31:0] reg_file[XLEN-1:0];

    // Decoded operands
    logic[4:0]  a1, a2, rd;

    logic[31:0] rs1, rs2;

    // Immediates
    logic[4:0]  imm_ext_shamt;
    logic[11:0] imm_ext_i;
    logic[11:0] imm_ext_s;
    logic[11:0] imm_ext_b;
    logic[19:0] imm_ext_j;
    logic[19:0] imm_ext_u;
    logic[31:0] imm_ext;

    // Control signals
    logic       register_write;
    logic[1:0]  result_src;
    logic       mem_store;
    logic       mem_load;
    logic       branch, jal, jalr;
    logic[3:0]  alu_control;
    logic       alu_src;
    logic[2:0]  imm_src;

    logic[2:0]  branch_op;
    logic[31:0] branch_result;

    assign do_branch = branch || jal || jalr;
    assign branch_op = if_id_inf.instr[14:12];

    // Extract control signals
    control ctrl(
        .op(if_id_inf.instr[6:0]),
        .funct3(if_id_inf.instr[14:12]),
        .funct7(if_id_inf.instr[31:25]),
        .result_src(result_src),
        .branch(branch),
        .jal(jal),
        .jalr(jalr),
        .mem_store(mem_store),
        .mem_load(mem_load),
        .alu_control(alu_control),
        .alu_src(alu_src),
        .imm_src(imm_src),
        .register_write(register_write));

    // Propagate control signals to EXE
    always_ff @(posedge clk) begin
        if (rst || flush_exe) begin
            id_exe_inf.ctrl.register_write <= 1'b0;
            id_exe_inf.ctrl.result_src <= 2'b0;
            id_exe_inf.ctrl.mem_store <= 1'b0;
            id_exe_inf.ctrl.mem_load <= 1'b0;
            id_exe_inf.ctrl.alu_control <= 4'b0;
            id_exe_inf.ctrl.alu_src <= 1'b0;
        end
        else begin
            id_exe_inf.ctrl.register_write <= register_write;
            id_exe_inf.ctrl.result_src <= result_src;
            id_exe_inf.ctrl.mem_store <= mem_store;
            id_exe_inf.ctrl.mem_load <= mem_load;
            id_exe_inf.ctrl.alu_control <= alu_control;
            id_exe_inf.ctrl.alu_src <= alu_src;
        end
    end

    // Decode SRC/DST operands
    assign a1 = if_id_inf.instr[19:15];
    assign a2 = if_id_inf.instr[24:20];
    assign rd = if_id_inf.instr[11:7];

    assign rs1_d = a1;
    assign rs2_d = a2;

    // Fetch operands (read-during-write mode!)
    assign rs1 = (a1 == 0) ? 32'h0 :
                 ((wb_id_inf.wr_en && (wb_id_inf.rd == a1)) ? wb_id_inf.wr_data :
                 reg_file[a1]);

    assign rs2 = (a2 == 0) ? 32'h0 :
                 ((wb_id_inf.wr_en && (wb_id_inf.rd == a2)) ? wb_id_inf.wr_data :
                 reg_file[a2]);

    assign imm_ext_i = if_id_inf.instr[31:20];
    assign imm_ext_s = {if_id_inf.instr[31:25], if_id_inf.instr[11:7]};
    assign imm_ext_b = {if_id_inf.instr[7], if_id_inf.instr[30:25], if_id_inf.instr[11:8], 1'b0};
    assign imm_ext_j = {if_id_inf.instr[19:12], if_id_inf.instr[20], if_id_inf.instr[30:21], 1'b0};
    assign imm_ext_shamt = if_id_inf.instr[24:20];
    assign imm_ext_u = if_id_inf.instr[31:12];

    // Decode immediates based on instruction type
    always_comb begin
        imm_ext = 32'h0;

        unique case (imm_src)
            3'b000: imm_ext = {{20{if_id_inf.instr[31]}}, imm_ext_i};
            3'b001: imm_ext = {{20{if_id_inf.instr[31]}}, imm_ext_s};
            3'b010: imm_ext = {{20{if_id_inf.instr[31]}}, imm_ext_b};
            3'b011: imm_ext = {{12{if_id_inf.instr[31]}}, imm_ext_j};
            3'b100: imm_ext = {27'b0, imm_ext_shamt};
            default: imm_ext = {imm_ext_u, 12'b0};
        endcase
    end    

    // Initialize x0 and SP/GP for simulation
    initial begin
        reg_file[0] = 0;
        reg_file[2] = SP;
        reg_file[3] = GP;
    end

    // Write register data
    always_ff @(posedge clk) begin
        if (wb_id_inf.wr_en)
            reg_file[wb_id_inf.rd] <= wb_id_inf.wr_data;
    end

    // Read register file
    always_ff @(posedge clk) begin
        id_exe_inf.rs1 <= rs1;
        id_exe_inf.rs2 <= rs2;
    end

    always_ff @(posedge clk) begin
        if (flush_exe) begin
            id_exe_inf.a1 <= 5'b0;
            id_exe_inf.a2 <= 5'b0;
            id_exe_inf.rd <= 5'b0;
        end
        else begin
            id_exe_inf.a1 <= a1;
            id_exe_inf.a2 <= a2;
            id_exe_inf.rd <= rd;
        end
    
        id_exe_inf.imm_ext <= imm_ext;
        id_exe_inf.pc <= if_id_inf.pc;
        id_exe_inf.pc_inc <= if_id_inf.pc_inc;
    end

    // Early branch resolution
    always_comb begin
        pc_src = 1'b0;

        branch_result = (fwd_branch_rs1 ? exe_alu_result : rs1) - (fwd_branch_rs2 ? exe_alu_result : rs2);
        
        //TODO: Remaining branch ops!!!

        if (jal || jalr)
            pc_src = 1'b1;
        else if (branch)
            pc_src = ((branch_op == 3'b0) && ~(|branch_result)) || ((branch_op == 3'b1) && (|branch_result));

        branch_target = imm_ext + (jalr ? (fwd_branch_rs1 ? exe_alu_result : rs1) : if_id_inf.pc);
        branch_target = {branch_target[31:1], 1'b0};
    end
endmodule