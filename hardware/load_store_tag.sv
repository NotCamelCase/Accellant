`include "defines.svh"
`include "memory_map.svh"

import defines::*;

module load_store_tag
(
    input logic                                 clk, rst,
    // WB -> LST
    input logic                                 wb_do_branch,
    // IX -> LST
    input logic                                 ix_lst_valid,
    input ix_lst_inf_t                          ix_lst_inf,
    // LSD -> LST
    input lsd_lst_inf_t                         lsd_lst_inf,
    // LST -> LSD
    output dcache_tag_t[DCACHE_NUM_WAYS-1:0]    lst_writeback_tags,
    output logic                                lst_valid,
    output lst_lsd_inf_t                        lst_lsd_inf
);
    // Memory location to access CL tags & valid bits.
    // It comprises of a base address (rs1) and an (immediate) offset
    logic[31:0]                 mem_addr;
    lsu_address_t               mem_addr_packed;

    logic[DCACHE_NUM_WAYS-1:0]  valid_bits;

    logic[3:0]                  store_byte_en;
    logic[3:0]                  sb_wr_en, sh_wr_en, sw_wr_en;
    logic[31:0]                 sb_wr_data, sh_wr_data, sw_wr_data;
    logic[31:0]                 write_data;

    logic                       io_access, cache_mem_access;

    // Compute memory location to be accessed
    assign mem_addr = ix_lst_inf.rs1 + ix_lst_inf.imm_ext;
    assign mem_addr_packed = lsu_address_t'(mem_addr);

    // True if the memory location is accessed within the uncacheable I/O address space
    assign io_access = ((mem_addr & MMIO_BASE_ADDRESS) == MMIO_BASE_ADDRESS) && !(ix_lst_inf.dcache_flush || ix_lst_inf.dcache_invalidate);
    // Let all non-I/O accesses go thru D$ (neglecting PFs!)
    assign cache_mem_access = !io_access && !(ix_lst_inf.dcache_flush || ix_lst_inf.dcache_invalidate);

    // Way memories
    generate
        for (genvar way_idx = 0; way_idx < DCACHE_NUM_WAYS; way_idx++) begin
            // CL valid lines
            logic   valid_bits_reg[DCACHE_NUM_SETS-1:0];

            always_ff @(posedge clk) begin
                if (rst || ix_lst_inf.dcache_invalidate) begin
                    for (int set_idx = 0; set_idx < DCACHE_NUM_SETS; set_idx++)
                        valid_bits_reg[set_idx] <= 1'b0;
                end else if (lsd_lst_inf.update_tag_en[way_idx])
                        valid_bits_reg[lsd_lst_inf.update_tag_set] <= 1'b1; // Set valid bit on CL fetch
            end

            // CL tags
            bram_2r1w #(.ADDR_WIDTH(DCACHE_NUM_SET_BITS), .DATA_WIDTH(DCACHE_NUM_TAG_BITS)) tags(
                .clk(clk),
                .wr_en(lsd_lst_inf.update_tag_en[way_idx]),
                .rd_en_a(ix_lst_valid),
                .rd_en_b(|1'b1), // No need to gate writeback tags retrieval
                .rd_addr_a(mem_addr_packed.set_idx),
                .rd_addr_b(lsd_lst_inf.evict_set),
                .wr_addr(lsd_lst_inf.update_tag_set),
                .wr_data(lsd_lst_inf.update_tag),
                .rd_data_a(lst_lsd_inf.tags_read[way_idx]),
                .rd_data_b(lst_writeback_tags[way_idx]));

            // Pass CL valid bit for way memory to LSU Data
            assign valid_bits[way_idx] = valid_bits_reg[mem_addr_packed.set_idx];
        end
    endgenerate

    // Align write data for SB/SH/SW
    always_comb begin
        unique case (mem_addr[1:0])
            2'b11: sb_wr_data = {ix_lst_inf.write_data[7:0], 24'b0};
            2'b10: sb_wr_data = {8'b0, ix_lst_inf.write_data[7:0], 16'b0};
            2'b01: sb_wr_data = {16'b0, ix_lst_inf.write_data[7:0], 8'b0};
            default: sb_wr_data = {24'b0, ix_lst_inf.write_data[7:0]};
        endcase
    end

    assign sh_wr_data = mem_addr[0] ? {ix_lst_inf.write_data[15:0], 16'b0} : {16'b0, ix_lst_inf.write_data[15:0]};
    assign sw_wr_data = ix_lst_inf.write_data;

    // Adjust byte-enable for SB/SH/SW
    assign sb_wr_en = 4'b0001 << mem_addr[1:0];
    assign sh_wr_en = mem_addr[0] ? 4'b1100 : 4'b0011;
    assign sw_wr_en = 4'b1111;

    // Byte-enable for word
    assign store_byte_en = ((ix_lst_inf.lsu_control[1:0] == STORE_OP_SB) ? sb_wr_en :
                           ((ix_lst_inf.lsu_control[1:0] == STORE_OP_SH) ? sh_wr_en :
                           sw_wr_en));

    // Compose write data here to register it ahead of IO interconnect
    assign write_data = ((ix_lst_inf.lsu_control[1:0] == STORE_OP_SB) ? sb_wr_data : 32'h0) ^
                        ((ix_lst_inf.lsu_control[1:0] == STORE_OP_SH) ? sh_wr_data : 32'h0) ^
                        ((ix_lst_inf.lsu_control[1:0] == STORE_OP_SW) ? sw_wr_data : 32'h0);

    // Outputs to LSD
    always_ff @(posedge clk) begin
        if (rst || wb_do_branch)
            lst_valid <= 1'b0;
        else
            lst_valid <= ix_lst_valid;
    end

    always_ff @(posedge clk) begin
        lst_lsd_inf.valid_bits <= valid_bits;
        lst_lsd_inf.register_write <= ix_lst_inf.register_write;
        lst_lsd_inf.mem_store <= ix_lst_inf.mem_store;
        lst_lsd_inf.mem_load <= ix_lst_inf.mem_load;
        lst_lsd_inf.dcache_flush <= ix_lst_inf.dcache_flush;
        lst_lsd_inf.dcache_invalidate <= ix_lst_inf.dcache_invalidate;
        lst_lsd_inf.cacheable_mem_access <= cache_mem_access;
        lst_lsd_inf.rd <= ix_lst_inf.rd;
        lst_lsd_inf.mem_addr <= mem_addr;
        lst_lsd_inf.mem_load_op <= load_op_e'(ix_lst_inf.lsu_control);
        lst_lsd_inf.write_strobe <= store_byte_en;
        lst_lsd_inf.write_data <= write_data;
        lst_lsd_inf.pc <= ix_lst_inf.pc;
        lst_lsd_inf.io_rd_en <= ix_lst_valid && !wb_do_branch && io_access && ix_lst_inf.mem_load;
        lst_lsd_inf.io_wr_en <= ix_lst_valid && !wb_do_branch && io_access && ix_lst_inf.mem_store;
    end
endmodule