module bram_2r1w
#
(
    parameter   ADDR_WIDTH  = 4,
    parameter   DATA_WIDTH  = 8,
    parameter   READ_BYPASS = 0
)
(
    input logic                     clk,
    input logic                     wr_en, rd_en_a, rd_en_b,
    input logic[ADDR_WIDTH-1:0]     rd_addr_a, rd_addr_b, wr_addr,
    input logic[DATA_WIDTH-1:0]     wr_data,
    output logic[DATA_WIDTH-1:0]    rd_data_a, rd_data_b
);
    // Instantiate two 1r1w BRAM modules to provide 2-read port/1-write port BRAM
    bram_1r1w #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH), .READ_BYPASS(READ_BYPASS)) bram_a(
        .clk(clk),
        .wr_en(wr_en),
        .rd_en(rd_en_a),
        .rd_addr(rd_addr_a),
        .wr_addr(wr_addr),
        .wr_data(wr_data),
        .rd_data(rd_data_a));

    bram_1r1w #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH), .READ_BYPASS(READ_BYPASS)) bram_b(
        .clk(clk),
        .wr_en(wr_en),
        .rd_en(rd_en_b),
        .rd_addr(rd_addr_b),
        .wr_addr(wr_addr),
        .wr_data(wr_data),
        .rd_data(rd_data_b));
endmodule