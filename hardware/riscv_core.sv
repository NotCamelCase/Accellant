`include "defines.svh"

module riscv_core
#
(
    parameter   TEST_PROG   = "test.mem",
    parameter   READ_HEX    = "YES"
)
(
    input logic         clk, rst,
    output logic[3:0]   led
);
    logic[3:0]  led_reg;

    always_ff @(posedge clk) led_reg <= {4{if_id_inf.pc == 32'h20}};

    assign led = led_reg;

    if_id_inf_t     if_id_inf;
    id_exe_inf_t    id_exe_inf;
    exe_mem_inf_t   exe_mem_inf;
    mem_wb_inf_t    mem_wb_inf;
    wb_id_inf_t     wb_id_inf;

    logic           pc_src, do_branch;
    logic[31:0]     branch_target;

    logic           lw_stall, branch_stall;
    logic           stall_fetch, stall_decode;
    logic           flush_decode, flush_exe;

    logic[1:0]      fwd_rs1, fwd_rs2;
    logic           fwd_branch_rs1, fwd_branch_rs2;
    logic[4:0]      rs1_d, rs2_d;

    // Bypass path for EXE
    always_comb begin
        fwd_rs1 = 2'b0;
        fwd_rs2 = 2'b0;

        if ((id_exe_inf.a1 == exe_mem_inf.rd) && exe_mem_inf.ctrl.register_write && (id_exe_inf.a1 != 0))
            fwd_rs1 = 2'b10; // Forward from MEM
        else if ((id_exe_inf.a1 == mem_wb_inf.rd) && mem_wb_inf.ctrl.register_write && (id_exe_inf.a1 != 0))
            fwd_rs1 = 2'b01; // Forward from WB

        if ((id_exe_inf.a2 == exe_mem_inf.rd) && exe_mem_inf.ctrl.register_write && (id_exe_inf.a2 != 0))
            fwd_rs2 = 2'b10; // Forward from MEM
        else if ((id_exe_inf.a2 == mem_wb_inf.rd) && mem_wb_inf.ctrl.register_write && (id_exe_inf.a1 != 0))
            fwd_rs2 = 2'b01; // Forward from WB
    end

    // Bypass path for EBR
    always_comb begin
        fwd_branch_rs1 = 1'b0;
        fwd_branch_rs2 = 1'b0;

        if ((rs1_d != 0) && (rs1_d == exe_mem_inf.rd) && exe_mem_inf.ctrl.register_write)
            fwd_branch_rs1 = 1'b1;

        if ((rs2_d != 0) && (rs2_d == exe_mem_inf.rd) && exe_mem_inf.ctrl.register_write)
            fwd_branch_rs2 = 1'b1;
    end

    // Resolve lw & control dependencies
    always_comb begin
        lw_stall = id_exe_inf.ctrl.mem_load &&
                   ((rs1_d == id_exe_inf.rd) || (rs2_d == id_exe_inf.rd));
        
        branch_stall = do_branch &&
                      ((id_exe_inf.ctrl.register_write && ((id_exe_inf.rd == rs1_d) || (id_exe_inf.rd == rs2_d))) ||
                      (exe_mem_inf.ctrl.mem_load && ((exe_mem_inf.rd == rs1_d) || (exe_mem_inf.rd == rs2_d))));

        stall_fetch = lw_stall || branch_stall;
        stall_decode = lw_stall || branch_stall;
        flush_decode = pc_src && (~branch_stall);
        flush_exe = lw_stall || branch_stall;
    end

    instruction_fetch #(.TEST_PROG(TEST_PROG), .READ_HEX(READ_HEX)) ifetch(
        .clk(clk),
        .rst(rst),
        .pc_src(pc_src),
        .branch_target(branch_target),
        .stall_fetch(stall_fetch),
        .stall_decode(stall_decode),
        .flush_decode(flush_decode),
        .if_id_inf(if_id_inf));

    instruction_decode idecode(
        .clk(clk),
        .rst(rst),
        .pc_src(pc_src),
        .do_branch(do_branch),
        .branch_target(branch_target),
        .flush_exe(flush_exe),
        .fwd_branch_rs1(fwd_branch_rs1),
        .fwd_branch_rs2(fwd_branch_rs2),
        .if_id_inf(if_id_inf),
        .exe_alu_result(exe_mem_inf.alu_result),
        .id_exe_inf(id_exe_inf),
        .wb_id_inf(wb_id_inf),
        .rs1_d(rs1_d),
        .rs2_d(rs2_d));

    exe_alu alu(
        .clk(clk),
        .rst(rst),
        .fwd_rs1(fwd_rs1),
        .fwd_rs2(fwd_rs2),
        .id_exe_inf(id_exe_inf),
        .exe_mem_inf(exe_mem_inf),
        .mem_alu_result(exe_mem_inf.alu_result),
        .wb_wr_data(wb_id_inf.wr_data));

    mem_lsu lsu(
        .clk(clk),
        .rst(rst),
        .exe_mem_inf(exe_mem_inf),
        .mem_wb_inf(mem_wb_inf));

    // Writeback to register file
    assign wb_id_inf.wr_en = mem_wb_inf.ctrl.register_write;
    assign wb_id_inf.rd = mem_wb_inf.rd;
    assign wb_id_inf.wr_data = (mem_wb_inf.ctrl.result_src == 2'b0) ? mem_wb_inf.alu_result :
                               ((mem_wb_inf.ctrl.result_src == 2'b01) ? mem_wb_inf.read_data :
                               mem_wb_inf.pc_inc);
endmodule