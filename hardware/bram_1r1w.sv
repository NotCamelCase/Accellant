module bram_1r1w
#
(
    parameter   ADDR_WIDTH          = 4,
    parameter   DATA_WIDTH          = 8,
    parameter   NUM_COL             = 1
)
(
    input logic                     clk,
    input logic[NUM_COL-1:0]        wr_en,
    input logic[ADDR_WIDTH-1:0]     rd_addr, wr_addr,
    input logic[DATA_WIDTH-1:0]     wr_data,
    output logic[DATA_WIDTH-1:0]    rd_data
);
    localparam  COL_WIDTH = DATA_WIDTH / NUM_COL;

    logic[DATA_WIDTH-1:0]   buffer[2**ADDR_WIDTH-1:0];
    logic[DATA_WIDTH-1:0]   data_reg;

    // Write port
    generate;
        for (genvar i = 0; i < NUM_COL; i++) begin
            always_ff @(posedge clk) begin
                if (wr_en[i])
                    buffer[wr_addr][i*COL_WIDTH +: COL_WIDTH] <= wr_data[i*COL_WIDTH +: COL_WIDTH];
            end
        end
    endgenerate

    // Read port (no-change mode)
    always_ff @(posedge clk) begin
        if (~(|wr_en))
            data_reg <= buffer[rd_addr];
    end

    assign rd_data = data_reg;
endmodule