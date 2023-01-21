module bram_1r1w
#
(
    parameter   ADDR_WIDTH  = 4,
    parameter   DATA_WIDTH  = 8,
    parameter   READ_BYPASS = 0
)
(
    input logic                     clk,
    input logic                     wr_en, rd_en,
    input logic[ADDR_WIDTH-1:0]     rd_addr, wr_addr,
    input logic[DATA_WIDTH-1:0]     wr_data,
    output logic[DATA_WIDTH-1:0]    rd_data
);
    logic                   data_hazard_reg;
    logic[DATA_WIDTH-1:0]   last_wr_data_reg;

    logic[DATA_WIDTH-1:0]   buffer[2**ADDR_WIDTH-1:0];
    logic[DATA_WIDTH-1:0]   data_reg;

    // Write port
    always_ff @(posedge clk) begin
        if (wr_en)
            buffer[wr_addr] <= wr_data;
    end

    // Read port (read-first mode)
    always_ff @(posedge clk) begin
        if (rd_en)
            data_reg <= buffer[rd_addr];
    end

    // Remember if a read-write collision has occurred last cycle
    always_ff @(posedge clk) data_hazard_reg <= rd_en && wr_en && (rd_addr == wr_addr);
    always_ff @(posedge clk) last_wr_data_reg <= wr_data;

    generate
        if (READ_BYPASS == 1)
            assign rd_data = data_hazard_reg ? last_wr_data_reg : data_reg;
        else
            assign rd_data = data_reg;
    endgenerate
endmodule